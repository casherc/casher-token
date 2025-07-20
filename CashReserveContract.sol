/**
 *Submitted for verification at BscScan.com on 2025-01-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}

contract TokenPurchase is IERC20 {
    using SafeMath for uint256;

    string public name = "Cash Reserve";
    string public symbol = "CASHER";
    uint8 public decimals = 18;
    uint256 public override totalSupply;
    uint256 public totalTokensSold;
    uint256 public constant MAX_TOKENS_SOLD = 30000000 * 10**18; 

    address public owner;
    uint256 public tokenPrice; 
    uint256 public bnbTokenPrice; 

    bool public inTransaction = false; 

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;

    event TokensPurchased(address indexed buyer, uint256 amount);
    event TokensPurchasedWithBNB(address indexed buyer, uint256 amount);

    IERC20 public usdtToken;

    constructor(uint256 _initialSupply, uint256 _initialTokenPrice, uint256 _initialBnbTokenPrice,address _owner,address _usdtToken) {
        owner = _owner;
        totalSupply = _initialSupply * 10**uint256(decimals);
        balances[owner] = totalSupply;
        tokenPrice = _initialTokenPrice;
        bnbTokenPrice = _initialBnbTokenPrice;

        emit Transfer(address(0), owner, totalSupply);
        usdtToken = IERC20(_usdtToken);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier lock() {
        require(!inTransaction, "Transaction is already in progress");
        inTransaction = true;
        _;
        inTransaction = false;
    }

    function setTokenPrice(uint256 _newTokenPrice) public onlyOwner {
        tokenPrice = _newTokenPrice;
    }

    function setBnbTokenPrice(uint256 _newBnbTokenPrice) public onlyOwner {
        bnbTokenPrice = _newBnbTokenPrice;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return allowances[owner][spender];
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }
    function _address() public view  returns (address) {
        return address(this);
    }


    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(balances[sender] >= amount, "ERC20: transfer amount exceeds balance");

        balances[sender] = balances[sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function buyTokens(uint256 usdtAmount) public lock {
        require(usdtAmount > 0 , "You need to send some USDT");
   
            
            uint256 tokenAmount = usdtAmount.mul(10 ** uint256(decimals)).div(tokenPrice);
            require(totalTokensSold.add(tokenAmount) <= MAX_TOKENS_SOLD, "Token sale limit reached");
            
            usdtToken.transferFrom(msg.sender, address(this), usdtAmount);
            _transfer(address(this), msg.sender, tokenAmount);
            
            totalTokensSold = totalTokensSold.add(tokenAmount);

            emit TokensPurchased(msg.sender, tokenAmount);
        }


    receive() external payable {
        buyTokensWithBNB();
    }

    function buyTokensWithBNB() public payable lock {
        require(msg.value > 0 , "You need to send some BNB");
        uint256 tokenAmount = msg.value.mul(10 ** uint256(decimals)).div(bnbTokenPrice);
       
        
        
        require(totalTokensSold.add(tokenAmount) <= MAX_TOKENS_SOLD, "Token sale limit reached");
        
        _transfer(address(this), msg.sender, tokenAmount);
        
        totalTokensSold = totalTokensSold.add(tokenAmount);

        emit TokensPurchasedWithBNB(msg.sender, tokenAmount);
    }

    function withdrawUSDT(uint256 amount) public onlyOwner {
        require(usdtToken.balanceOf(address(this)) >= amount, "Not enough USDT in the contract");
        usdtToken.transfer(owner, amount);
    }

    function withdrawTokens(uint256 amount) public onlyOwner {
        require(balances[address(this)] >= amount, "Not enough tokens in the contract");
        _transfer(address(this), owner, amount);
    }

    function withdrawBNB(uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Not enough BNB in the contract");
         (bool sent, ) = payable(owner).call{value : amount }("");
        require(sent,"Faild"); 
        
    }


}