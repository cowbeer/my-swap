// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MySwap {
    IERC20 public immutable tokenA;
    IERC20 public immutable tokenB;

    uint public reserveA;
    uint public reserveB;

    uint public totalSupply;
    mapping(address => uint) public balanceOf;


    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    function _sqrt(uint y) private pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function _min(uint _x, uint _y) private pure returns(uint) {
        return _x > _y ? _y : _x;
    }

    function _mint(address _to, uint _amount) private {
        balanceOf[_to] += _amount;
        totalSupply += _amount;
    }

    function _burn(address _to, uint _amount) private {
        balanceOf[_to] -= _amount;
        totalSupply -= _amount;
    }

    function _update(uint _reserveA, uint _reserveB) private {
        reserveA = _reserveA;
        reserveB = _reserveB;
    }

    function swap(address _tokenIn, uint _amountIn) external returns (uint) {
        require(_amountIn > 0, "Invalid amount");
        require(IERC20(_tokenIn) == tokenA || IERC20(_tokenIn) == tokenB, "Invlaid input token address");

        bool isTokenA = IERC20(_tokenIn) == tokenA;
        (IERC20 tokenIn, IERC20 tokenOut) = isTokenA ? (tokenA, tokenB) : (tokenB, tokenA);
        (uint reserveIn, uint reserveOut) = isTokenA ? (reserveA, reserveB) : (reserveB , reserveA);

        // transfer input token from user to this contract.
        tokenIn.transferFrom(msg.sender, address(this), _amountIn);

        // calc the output amount
        uint amountOut = _amountIn * reserveOut / (reserveIn + _amountIn);

        // transfer output token to user
        tokenOut.transfer(msg.sender, amountOut);

        // update
        _update(tokenA.balanceOf(address(this)),tokenB.balanceOf(address(this)));

        return amountOut;
    }

    function addLiquidity(uint _amountA, uint _amountB) external returns (uint) {
        require(_amountA > 0 && _amountB > 0, "Invalid amount");
        tokenA.transferFrom(msg.sender, address(this), _amountA);
        tokenB.transferFrom(msg.sender, address(this), _amountB);

        if (reserveA > 0 || reserveB > 0) {
            require(_amountA * reserveB == _amountB * reserveA, "dy/dx != y/x");
        }

        uint shares = 0;
        if (totalSupply == 0) {
            shares = _sqrt(_amountA * _amountB);
        } else {
            shares = _min(_amountA * totalSupply / reserveA, _amountB * totalSupply / reserveB);
        }
        require(shares > 0, "share is zero");

        _mint(msg.sender, shares);

        _update(tokenA.balanceOf(address(this)),tokenB.balanceOf(address(this)));

        return shares;
    }

    function removeLiquidity(uint _shares) external returns(uint, uint) {
        require(_shares > 0, "Invalid shares");

        uint amountA = _shares * reserveA / totalSupply;
        uint amountB = _shares * reserveB / totalSupply;

        _burn(msg.sender, _shares);

        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);

        _update(tokenA.balanceOf(address(this)),tokenB.balanceOf(address(this)));

        return (amountA, amountB);
    }
}
