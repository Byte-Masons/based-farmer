// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface ICurveLiquidityPool {
    function add_liquidity(
        uint256[3] memory amounts,
        uint256 min_mint_amount,
        bool _use_underlying
    ) external;

    function token() external returns (address);
}