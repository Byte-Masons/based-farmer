// SPDX-License-Identifier: MIT

import './abstract/ReaperBaseStrategy.sol';
import './interfaces/IUniswapV2Pair.sol';
import './interfaces/IUniswapV2Router02.sol';
import './interfaces/IMasterChef.sol';
import './interfaces/ICurveGauge.sol';
import './interfaces/ICurveLiquidityPool.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';

pragma solidity 0.8.11;

/**
 * @dev This strategy will farm Based LPs on Spooky and autocompound rewards
 */
contract ReaperAutoCompoundBasedFarmer is ReaperBaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @dev Tokens Used:
     * {WFTM} - Required for liquidity routing when doing swaps. Also used to charge fees on yield.
     * {BSHARE} - The reward token
     * {want} - The vault token the strategy is maximizing
     * {liquidityToken} - Part of the LP token used to deposit into and make the LP
     * {liquidityPool} - The Curve liquidity pool to deposit into (could be Curve Tricrypto)
     */
    address public constant WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    address public constant BSHARE = 0x49C290Ff692149A4E16611c694fdED42C954ab7a;
    address public want;
    address public liquidityToken;
    address public liquidityPool;

    /**
     * @dev Third Party Contracts:
     * {MASTER_CHEF} - The Based MasterChef for staking LPs and collecting rewards
     * {SPOOKY_ROUTER} - Spooky router for swapping tokens
     */
    address public constant MASTER_CHEF = 0xAc0fa95058616D7539b6Eecb6418A68e7c18A746;
    address public constant SPOOKY_ROUTER = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;

    /**
     * @dev Based variables:
     * {poolId} - The MasterChef poolId for the want
     * {liquidityIndex} - The index in the Curve LP for the token used to make the LP
     */
    uint256 public poolId;
    uint256 public liquidityIndex;

    /**
     * @dev Initializes the strategy. Sets parameters, saves routes, and gives allowances.
     * @notice see documentation for each variable above its respective declaration.
     */
    function initialize(
        address _vault,
        address[] memory _feeRemitters,
        address[] memory _strategists,
        address _want,
        address _liquidityPool,
        address _liquidityToken,
        uint256 _liquidityIndex,
        uint256 _poolId
    ) public initializer {
        __ReaperBaseStrategy_init(_vault, _feeRemitters, _strategists);
        want = _want;
        liquidityPool = _liquidityPool;
        liquidityToken = _liquidityToken;
        liquidityIndex = _liquidityIndex;
        poolId = _poolId;
        _giveAllowances();
    }

    /**
     * @dev Withdraws funds and sents them back to the vault.
     * It withdraws {want} from the Based MasterChef
     * The available {want} minus fees is returned to the vault.
     */
    function withdraw(uint256 _amount) external {
        require(msg.sender == vault, '!vault');
        require(_amount != 0, '0 amount');
        require(_amount <= balanceOf(), 'invalid amount');

        uint256 wantBal = IERC20Upgradeable(want).balanceOf(address(this));
        if (wantBal < _amount) {
            IMasterChef(MASTER_CHEF).withdraw(poolId, _amount - wantBal);
        }

        uint256 withdrawFee = (_amount * securityFee) / PERCENT_DIVISOR;
        IERC20Upgradeable(want).safeTransfer(vault, _amount - withdrawFee);
    }

    /**
     * @dev Returns the approx amount of profit from harvesting.
     *      Profit is denominated in WFTM, and takes fees into account.
     */
    function estimateHarvest() external view override returns (uint256 profit, uint256 callFeeToUser) {
        uint256 pendingReward = IMasterChef(MASTER_CHEF).pendingShare(poolId, address(this));

        uint256 freeRewards = IERC20Upgradeable(BSHARE).balanceOf(address(this));
        uint256 totalRewards = pendingReward + freeRewards;

        if (totalRewards == 0) {
            return (0, 0);
        }

        address[] memory rewardToWftmPath = new address[](2);
        rewardToWftmPath[0] = BSHARE;
        rewardToWftmPath[1] = WFTM;
        uint256[] memory amountOutMins = IUniswapV2Router02(SPOOKY_ROUTER).getAmountsOut(
            totalRewards,
            rewardToWftmPath
        );
        profit += amountOutMins[1];

        uint256 wftmFee = (profit * totalFee) / PERCENT_DIVISOR;
        callFeeToUser = (wftmFee * callFee) / PERCENT_DIVISOR;
        profit -= wftmFee;
    }

    /**
     * @dev Function to retire the strategy. Claims all rewards and withdraws
     *      all principal from external contracts, and sends everything back to
     *      the vault. Can only be called by strategist or owner.
     *
     * Note: this is not an emergency withdraw function. For that, see panic().
     */
    function retireStrat() external {
        _onlyStrategistOrOwner();

        _claimRewards();
        _swapTokens(BSHARE, WFTM, IERC20Upgradeable(BSHARE).balanceOf(address(this)));
        _addLiquidity();

        uint256 poolBalance = balanceOfPool();
        if (poolBalance != 0) {
            IMasterChef(MASTER_CHEF).withdraw(poolId, poolBalance);
        }
        uint256 wantBalance = IERC20Upgradeable(want).balanceOf(address(this));
        IERC20Upgradeable(want).safeTransfer(vault, wantBalance);
    }

    /**
     * @dev Sets the token in the curve LP used to make the LP (could be fusdt, wbtc, weth)
     */
    function setLiquidityInfo(address _liquidityToken, uint256 _liquidityIndex) external {
        _onlyStrategistOrOwner();
        liquidityToken = _liquidityToken;
        liquidityIndex = _liquidityIndex;
    }

    /**
     * @dev Pauses supplied. Withdraws all funds from the MasterChef.
     */
    function panic() external {
        _onlyStrategistOrOwner();
        IMasterChef(MASTER_CHEF).emergencyWithdraw(poolId);
        pause();
    }

    /**
     * @dev Unpauses the strat.
     */
    function unpause() external {
        _onlyStrategistOrOwner();
        _unpause();
        _giveAllowances();
        deposit();
    }

    /**
     * @dev Pauses the strat.
     */
    function pause() public {
        _onlyStrategistOrOwner();
        _pause();
        _removeAllowances();
    }

    /**
     * @dev Function that puts the funds to work.
     * It gets called whenever someone supplied in the strategy's vault contract.
     * It supplies {want} to farm {BSHARE}
     */
    function deposit() public whenNotPaused {
        uint256 wantBal = IERC20Upgradeable(want).balanceOf(address(this));

        if (wantBal != 0) {
            IMasterChef(MASTER_CHEF).deposit(poolId, wantBal);
        }
    }

    /**
     * @dev Calculates the total amount of {want} held by the strategy
     * which is the balance of want + the total amount supplied.
     */
    function balanceOf() public view override returns (uint256) {
        return balanceOfWant() + balanceOfPool();
    }

    /**
     * @dev Calculates the total amount of {want} held in the MasterChef
     */
    function balanceOfPool() public view returns (uint256) {
        (uint256 _amount, ) = IMasterChef(MASTER_CHEF).userInfo(poolId, address(this));
        return _amount;
    }

    /**
     * @dev Calculates the balance of want held directly by the strategy
     */
    function balanceOfWant() public view returns (uint256) {
        return IERC20Upgradeable(want).balanceOf(address(this));
    }

    /**
     * @dev Core function of the strat, in charge of collecting and re-investing rewards.
     * 1. Claims {BSHARE} from the MasterChef.
     * 2. Charges fees for the harvest caller and treasury.
     * 3. Converts tokens to {want}.
     * 4. Deposits in the MasterChef.
     */
    function _harvestCore() internal override {
        _claimRewards();
        _swapAndChargeFees();
        _addLiquidity();
        deposit();
    }

    /**
     * @dev Core harvest function.
     * Get rewards from the MasterChef
     */
    function _claimRewards() internal {
        IMasterChef(MASTER_CHEF).deposit(poolId, 0);
    }

    function _swapTokens(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_from == _to || _amount == 0) {
            return;
        }

        address[] memory path = new address[](2);
        path[0] = _from;
        path[1] = _to;
        IUniswapV2Router02(SPOOKY_ROUTER).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    /**
     * @dev Core harvest function.
     * Charges fees based on the amount of WFTM gained from reward
     */
    function _swapAndChargeFees() internal {
        _swapTokens(BSHARE, WFTM, IERC20Upgradeable(BSHARE).balanceOf(address(this)));
        uint256 wftmFee = (IERC20Upgradeable(WFTM).balanceOf(address(this)) * totalFee) / PERCENT_DIVISOR;

        if (wftmFee == 0) {
            return;
        }

        uint256 callFeeToUser = (wftmFee * callFee) / PERCENT_DIVISOR;
        uint256 treasuryFeeToVault = (wftmFee * treasuryFee) / PERCENT_DIVISOR;
        uint256 feeToStrategist = (treasuryFeeToVault * strategistFee) / PERCENT_DIVISOR;
        treasuryFeeToVault -= feeToStrategist;

        IERC20Upgradeable(WFTM).safeTransfer(msg.sender, callFeeToUser);
        IERC20Upgradeable(WFTM).safeTransfer(treasury, treasuryFeeToVault);
        IERC20Upgradeable(WFTM).safeTransfer(strategistRemitter, feeToStrategist);
    }

    /** @dev Converts WFTM to both sides of the LP token and builds the liquidity pair */
    function _addLiquidity() internal {
        uint256 wftmBalance = IERC20Upgradeable(WFTM).balanceOf(address(this));
        if (wftmBalance == 0) {
            return;
        }

        _swapTokens(WFTM, liquidityToken, wftmBalance);

        uint256 liquidityTokenBalance = IERC20Upgradeable(liquidityToken).balanceOf(address(this));
        uint256[3] memory amounts;
        amounts[liquidityIndex] = liquidityTokenBalance;
        ICurveLiquidityPool(liquidityPool).add_liquidity(amounts, 0);
    }

    /**
     * @dev Gives the necessary allowances
     */
    function _giveAllowances() internal {
        // want -> MASTER_CHEF
        uint256 wantAllowance = type(uint256).max - IERC20Upgradeable(want).allowance(address(this), MASTER_CHEF);
        IERC20Upgradeable(want).safeIncreaseAllowance(MASTER_CHEF, wantAllowance);
        // reward token -> SPOOKY_ROUTER
        uint256 bshareAllowance = type(uint256).max - IERC20Upgradeable(BSHARE).allowance(address(this), SPOOKY_ROUTER);
        IERC20Upgradeable(BSHARE).safeIncreaseAllowance(SPOOKY_ROUTER, bshareAllowance);
        // WFTM -> SPOOKY_ROUTER
        uint256 wftmAllowance = type(uint256).max - IERC20Upgradeable(WFTM).allowance(address(this), SPOOKY_ROUTER);
        IERC20Upgradeable(WFTM).safeIncreaseAllowance(SPOOKY_ROUTER, wftmAllowance);
        // liquidityToken -> liquidityPool
        uint256 liquidityTokenAllowance = type(uint256).max - IERC20Upgradeable(liquidityToken).allowance(address(this), liquidityPool);
        IERC20Upgradeable(liquidityToken).safeIncreaseAllowance(liquidityPool, liquidityTokenAllowance);
    }

    /**
     * @dev Removes all allowance that were given
     */
    function _removeAllowances() internal {
        IERC20Upgradeable(want).safeDecreaseAllowance(
            MASTER_CHEF,
            IERC20Upgradeable(want).allowance(address(this), MASTER_CHEF)
        );
        IERC20Upgradeable(BSHARE).safeDecreaseAllowance(
            SPOOKY_ROUTER,
            IERC20Upgradeable(BSHARE).allowance(address(this), SPOOKY_ROUTER)
        );
        IERC20Upgradeable(WFTM).safeDecreaseAllowance(
            SPOOKY_ROUTER,
            IERC20Upgradeable(WFTM).allowance(address(this), SPOOKY_ROUTER)
        );
        IERC20Upgradeable(liquidityToken).safeDecreaseAllowance(
            liquidityPool,
            IERC20Upgradeable(liquidityToken).allowance(address(this), liquidityPool)
        );
    }
}
