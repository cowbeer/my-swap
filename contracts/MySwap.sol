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

    function addLiquidity() external {}

    function removeLiquidity() external {}
}
