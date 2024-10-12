
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// File: contracts/swap.sol


pragma solidity ^0.8.0;


contract LiquidityPool {
    IERC20 public tokenA;
    IERC20 public tokenB;

    uint256 public reserveA; // Updated reserveA
    uint256 public reserveB; // Updated reserveB

    mapping(address => uint256) public liquidity;

    event LiquidityAdded(address indexed provider, uint256 tokenAAmount, uint256 tokenBAmount);
    event LiquidityRemoved(address indexed provider, uint256 amount);
    event Swap(address indexed user, string swapDirection, uint256 inputAmount, uint256 outputAmount);

    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    function updateReserves() internal {
        reserveA = tokenA.balanceOf(address(this));
        reserveB = tokenB.balanceOf(address(this));
    }

    function addLiquidity(uint256 tokenAAmount, uint256 tokenBAmount) external {
        require(tokenA.transferFrom(msg.sender, address(this), tokenAAmount), "Token A transfer failed");
        require(tokenB.transferFrom(msg.sender, address(this), tokenBAmount), "Token B transfer failed");
        liquidity[msg.sender] += tokenAAmount + tokenBAmount;
        updateReserves();
        emit LiquidityAdded(msg.sender, tokenAAmount, tokenBAmount);
    }

    function removeLiquidity(uint256 amount) external {
        require(liquidity[msg.sender] >= amount, "Not enough liquidity");

        uint256 tokenAAmount = (amount * reserveA) / (reserveA + reserveB);
        uint256 tokenBAmount = (amount * reserveB) / (reserveA + reserveB);
        liquidity[msg.sender] -= amount;
        require(tokenA.transfer(msg.sender, tokenAAmount), "Token A transfer failed");
        require(tokenB.transfer(msg.sender, tokenBAmount), "Token B transfer failed");
        updateReserves();

        emit LiquidityRemoved(msg.sender, amount);
    }

    function swapTokenAForTokenB(uint256 tokenAAmount) external {
        require(tokenAAmount > 0, "Invalid input amount");
        uint256 tokenBAmount = (tokenAAmount * reserveB) / reserveA;
        require(tokenBAmount > 0 && tokenBAmount <= reserveB, "Insufficient liquidity");
        require(tokenA.transferFrom(msg.sender, address(this), tokenAAmount), "Token A transfer failed");
        require(tokenB.transfer(msg.sender, tokenBAmount), "Token B transfer failed");
        updateReserves();
        emit Swap(msg.sender, "A to B", tokenAAmount, tokenBAmount);
    }

    function swapTokenBForTokenA(uint256 tokenBAmount) external {
        require(tokenBAmount > 0, "Invalid input amount");
        uint256 tokenAAmount = (tokenBAmount * reserveA) / reserveB;
        require(tokenAAmount > 0 && tokenAAmount <= reserveA, "Insufficient liquidity");
        require(tokenB.transferFrom(msg.sender, address(this), tokenBAmount), "Token B transfer failed");
        require(tokenA.transfer(msg.sender, tokenAAmount), "Token A transfer failed");
        updateReserves();
        emit Swap(msg.sender, "B to A", tokenBAmount, tokenAAmount);
    }
}
