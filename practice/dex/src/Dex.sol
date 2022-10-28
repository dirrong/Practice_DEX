// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "lib/forge-std/src/console.sol";

contract Dex is ERC20 {
    using SafeERC20 for IERC20;

    IERC20 _tokenX;
    IERC20 _tokenY;

    constructor(address tokenX, address tokenY) ERC20("DreamAcademy DEX LP token", "DA-DEX-LP") {
        require(tokenX != tokenY, "DA-DEX: Tokens should be different");

        _tokenX = IERC20(tokenX);
        _tokenY = IERC20(tokenY);
    }

    function swap(uint256 tokenXAmount, uint256 tokenYAmount, uint256 tokenMinimumOutputAmount)
        external
        returns (uint256 outputAmount)
    {
        //require(tokenXAmount == 0 || tokenYAmount == 0);
        uint256 balanceX = _tokenX.balanceOf(address(this));
        uint256 balanceY = _tokenY.balanceOf(address(this));
        // console.log("balanceX:", balanceX);
        // console.log("balanceY:", balanceY);

        uint256 k = balanceX * balanceY;
        
        require(k != 0);

        if (tokenXAmount == 0) {
            // Y -> X
            // console.log(k);
            // console.log(balanceX);
            // console.log(balanceY);

            uint256 xReturn = balanceX - (k / (balanceY + tokenYAmount));
            uint256 xOut = xReturn * 999/1000;

            require(xOut >= tokenMinimumOutputAmount);

            _tokenY.safeTransferFrom(msg.sender, address(this), tokenYAmount);
            _tokenX.safeTransfer(msg.sender, xOut);

            return xOut;

        } else if (tokenYAmount == 0) {
            // X -> Y
            uint256 yReturn = balanceY - (k / (balanceX + tokenXAmount));
            uint256 yOut = yReturn * 999/1000;

            require(yOut >= tokenMinimumOutputAmount);

            _tokenX.safeTransferFrom(msg.sender, address(this), tokenXAmount);
            _tokenY.safeTransfer(msg.sender, yOut);

            return yOut;
        } else {
            revert("X or Y should be 0");
        }

    }

    function addLiquidity(uint256 tokenXAmount, uint256 tokenYAmount, uint256 minimumLPTokenAmount)
        external
        returns (uint256 LPTokenAmount)
    {
        require(tokenXAmount != 0 && tokenYAmount != 0);
        
        uint256 balanceX = _tokenX.balanceOf(address(this));
        uint256 balanceY = _tokenY.balanceOf(address(this));

        uint256 After_balanceX = balanceX + tokenXAmount;
        uint256 After_balanceY = balanceY + tokenYAmount;

        uint256 before_k = balanceX * balanceY;
        uint256 after_k = After_balanceX * After_balanceY;

        uint256 firstliquidity = totalSupply();

        uint256 afterliquidity;

        if (firstliquidity == 0 || before_k == 0) {
            afterliquidity = sqrt(after_k);
        } else {
            uint256 afterliquidity_X = firstliquidity * (After_balanceX/balanceX);
            uint256 afterliquidity_Y = firstliquidity * (After_balanceY/balanceY);

            if (afterliquidity_X >= afterliquidity_Y) {
                afterliquidity = afterliquidity_Y;
            } else {
                afterliquidity = afterliquidity_X;
            }
        }

        uint256 lpamount = afterliquidity - firstliquidity;
        require(lpamount >= minimumLPTokenAmount);

        _tokenX.safeTransferFrom(msg.sender, address(this), tokenXAmount);
        _tokenY.safeTransferFrom(msg.sender, address(this), tokenYAmount);

        // lp 토큰 mint
        _mint(msg.sender, lpamount);
        // return liquidity 양
        return lpamount;
    }

    function removeLiquidity(uint256 LPTokenAmount, uint256 minimumTokenXAmount, uint256 minimumTokenYAmount)
        external returns (uint256 transferX, uint256 transferY)
    {
        require(LPTokenAmount <= balanceOf(msg.sender));
        uint256 liquidity = totalSupply();

        uint256 balanceX = _tokenX.balanceOf(address(this));
        uint256 balanceY = _tokenY.balanceOf(address(this));

        transferX = balanceX * LPTokenAmount / liquidity;
        transferY = balanceY * LPTokenAmount / liquidity;

        require(transferX >= minimumTokenXAmount);
        require(transferY >= minimumTokenYAmount);

        _burn(msg.sender, LPTokenAmount);
        _tokenX.safeTransfer(msg.sender, transferX);
        _tokenY.safeTransfer(msg.sender, transferY);
    }

    // From UniSwap core
    function sqrt(uint256 y) private pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
