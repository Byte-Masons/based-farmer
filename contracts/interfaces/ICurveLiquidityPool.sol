// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface ICurveLiquidityPool {
    function add_liquidity(uint256[3] memory _amounts, uint256 _min_mint_amount) external;
}