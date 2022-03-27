// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IFactoryV2.sol";
import "./IERC20.sol";
import "./IUniswapV2Pair.sol";
import "./SafeMath.sol";
import "./Context.sol";
import "./Address.sol";

contract Token is Context, IERC20 {
  using SafeMath for uint256;
  using Address for address;
  using SafeERC20 for IERC20;

  address dead = 0x000000000000000000000000000000000000dEaD;

  uint8 public maxFee = 20;
  uint8 public minMxTxPer = 1;
  uint8 public minMxWalletPer = 1;

  mapping (address => uint256) private _rOwned;
  mapping (address => uint256) private _tOwned;
  mapping (address => mapping (address => uint256)) private _allowances;

  mapping (address => bool) private _isExcludedFromFee;

  mapping (address => bool) private _isExcluded;
  address[] private _excluded;

  uint256 private constant MAX = ~uint256(0);
  uint256 public _tTotal;
  uint256 private _rTotal;
  uint256 private _tFeeTotal;

  string public _name;
  string public _symbol;
  uint8 private _decimals;

  uint8 public _taxFee = 0;
  uint8 private _prvTaxFee = _taxFee;

  uint8 public _liquidityFee = 0;
  uint8 private _prvLiquidityFee = _liquidityFee;

  uint8 public _burnFee = 0;
  uint8 private _prvBurnFee = _burnFee;

  uint8 public _walletFee = 0;
  uint8 private _prvWalletFee = _walletFee;

  uint8 public _buybackFee = 0;
  uint8 private _prvBuybackFee = _buybackFee;

  IUniswapV2Router02 public immutable pcsV2Router;
  address public immutable pcsV2Pair;
  address payable public feeWallet;
  address public _routerAddress;
  bool inSwapAndLiquify;
  bool public swapAndLiquifyEnabled = true;
  bool public touchedByMidas = true;

  uint256 public _maxTxAmount;
  uint256 public _maxWalletAmount;
  uint256 public numTokensSellToAddToLiquidity;
  uint256 private buyBackUpperLimit = 1 * 10**18;

  event SwapAndLiquifyEnabledUpdated(bool enabled);
  event SwapAndLiquify(
    uint256 tokensSwapped,
    uint256 ethReceived,
    uint256 tokensIntoLiqudity
  );

  modifier onlyOwner() {
      require(this.getOwner() == msg.sender, "onlyOwner");
      _;
  }

  modifier lockTheSwap {
    inSwapAndLiquify = true;
    _;
    inSwapAndLiquify = false;
  }

  constructor (address tokenOwner,string memory tokenName,
    string memory tokenSymbol, uint8 decimal, uint256 amountOfTokenWei,
    uint8 setMxTxPer, uint8 setMxWalletPer,
    address payable _feeWallet,
    address routerAddress
  )  {

    _name = tokenName;
    _symbol = tokenSymbol;
    _decimals = decimal;
    _tTotal = amountOfTokenWei;
    _rTotal = (MAX - (MAX % _tTotal));

    _routerAddress = routerAddress;   // bsc
    //address public router = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;   // bsc
    //address public router = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // pancake bsc main
    //address public router = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;

    _rOwned[tokenOwner] = _rTotal;

    feeWallet = _feeWallet;


    _maxTxAmount = _tTotal.mul(setMxTxPer).div(
      10**2
    );
    _maxWalletAmount = _tTotal.mul(setMxWalletPer).div(
      10**2
    );

    numTokensSellToAddToLiquidity = amountOfTokenWei.mul(1).div(1000);

    IUniswapV2Router02 _pcsV2Router = IUniswapV2Router02(_routerAddress);
    // Create a uniswap pair for this new token
    pcsV2Pair = IUniswapV2Factory(_pcsV2Router.factory())
    .createPair(address(this), _pcsV2Router.WETH());

    // set the rest of the contract variables
    pcsV2Router = _pcsV2Router;

    _isExcludedFromFee[tokenOwner] = true;
    _isExcludedFromFee[address(this)] = true;

    emit Transfer(address(0), tokenOwner, _tTotal);
  }

  function getOwner() external override view returns (address) {
    return 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function decimals() public view returns (uint8) {
    return _decimals;
  }

  function totalSupply() public view override returns (uint256) {
    return _tTotal;
  }

  function balanceOf(address account) public view override returns (uint256) {
    if (_isExcluded[account]) return _tOwned[account];
    return tokenFromReflection(_rOwned[account]);
  }

  function transfer(address recipient, uint256 amount) public override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) public view override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
    return true;
  }

  function isExcludedFromReward(address account) public view returns (bool) {
    return _isExcluded[account];
  }

  function totalFees() public view returns (uint256) {
    return _tFeeTotal;
  }

  function deliver(uint256 tAmount) public {
    address sender = _msgSender();
    require(!_isExcluded[sender], "Excluded");
    (uint256 rAmount,,,,,) = _getValues(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rTotal = _rTotal.sub(rAmount);
    _tFeeTotal = _tFeeTotal.add(tAmount);
  }

  function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
    require(tAmount <= _tTotal, "Amt must be less than supply");
    if (!deductTransferFee) {
      (uint256 rAmount,,,,,) = _getValues(tAmount);
      return rAmount;
    } else {
      (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
      return rTransferAmount;
    }
  }

  function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
    require(rAmount <= _rTotal, "Amt must be less than tot refl");
    uint256 currentRate =  _getRate();
    return rAmount.div(currentRate);
  }

  function excludeFromReward(address account) public onlyOwner() {
    require(!_isExcluded[account], "already excluded");
    if(_rOwned[account] > 0) {
      _tOwned[account] = tokenFromReflection(_rOwned[account]);
    }
    _isExcluded[account] = true;
    _excluded.push(account);
  }

  function includeInReward(address account) external onlyOwner() {
    require(_isExcluded[account], "already included");
    for (uint256 i = 0; i < _excluded.length; i++) {
      if (_excluded[i] == account) {
        _excluded[i] = _excluded[_excluded.length - 1];
        _tOwned[account] = 0;
        _isExcluded[account] = false;
        _excluded.pop();
        break;
      }
    }
  }

  function excludeFromFee(address account) public onlyOwner {
    _isExcludedFromFee[account] = true;
  }

  function includeInFee(address account) public onlyOwner {
    _isExcludedFromFee[account] = false;
  }

  function setAllFeePercent(uint8 taxFee, uint8 liquidityFee, uint8 burnFee, uint8 walletFee, uint8 buybackFee) external onlyOwner() {
    require(taxFee >= 0 && taxFee <=maxFee,"TF err");
    require(liquidityFee >= 0 && liquidityFee <=maxFee,"LF err");
    require(burnFee >= 0 && burnFee <=maxFee,"BF err");
    require(walletFee >= 0 && walletFee <=maxFee,"WF err");
    require(buybackFee >= 0 && buybackFee <=maxFee,"BBF err");
    _taxFee = taxFee;
    _liquidityFee = liquidityFee;
    _burnFee = burnFee;
    _buybackFee = buybackFee;
    _walletFee = walletFee;
  }

  function buyBackUpperLimitAmount() public view returns (uint256) {
    return buyBackUpperLimit;
  }

  function setBuybackUpperLimit(uint256 buyBackLimit) external onlyOwner() {
    buyBackUpperLimit = buyBackLimit * 10**18;
  }

  function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
    require(maxTxPercent >= minMxTxPer && maxTxPercent <=100,"err");
    _maxTxAmount = _tTotal.mul(maxTxPercent).div(
      10**2
    );
  }

  function setMaxWalletPercent(uint256 maxWalletPercent) external onlyOwner() {
    require(maxWalletPercent >= minMxWalletPer && maxWalletPercent <=100,"err");
    _maxWalletAmount = _tTotal.mul(maxWalletPercent).div(
      10**2
    );
  }

  function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
    swapAndLiquifyEnabled = _enabled;
    emit SwapAndLiquifyEnabledUpdated(_enabled);
  }

  function setFeeWallet(address payable newFeeWallet) external onlyOwner {
    feeWallet = newFeeWallet;
  }


  //to recieve ETH from pcsV2Router when swaping
  receive() external payable {}

  function _reflectFee(uint256 rFee, uint256 tFee) private {
    _rTotal = _rTotal.sub(rFee);
    _tFeeTotal = _tFeeTotal.add(tFee);
  }

  function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
    (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
    return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
  }

  function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
    uint256 tFee = calculateTaxFee(tAmount);
    uint256 tLiquidity = calculateLiquidityFee(tAmount);
    uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
    return (tTransferAmount, tFee, tLiquidity);
  }

  function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
    uint256 rAmount = tAmount.mul(currentRate);
    uint256 rFee = tFee.mul(currentRate);
    uint256 rLiquidity = tLiquidity.mul(currentRate);
    uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
    return (rAmount, rTransferAmount, rFee);
  }

  function _getRate() private view returns(uint256) {
    (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
    return rSupply.div(tSupply);
  }

  function _getCurrentSupply() private view returns(uint256, uint256) {
    uint256 rSupply = _rTotal;
    uint256 tSupply = _tTotal;
    for (uint256 i = 0; i < _excluded.length; i++) {
      if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
      rSupply = rSupply.sub(_rOwned[_excluded[i]]);
      tSupply = tSupply.sub(_tOwned[_excluded[i]]);
    }
    if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
    return (rSupply, tSupply);
  }

  function _takeLiquidity(uint256 tLiquidity) private {
    uint256 currentRate =  _getRate();
    uint256 rLiquidity = tLiquidity.mul(currentRate);
    _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
    if(_isExcluded[address(this)])
      _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
  }

  function calculateTaxFee(uint256 _amount) private view returns (uint256) {
    return _amount.mul(_taxFee).div(
      10**2
    );
  }

  function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
    return _amount.mul(_liquidityFee + _burnFee + _walletFee + _buybackFee).div(
      10**2
    );
  }

  function removeAllFee() private {
    if(_taxFee == 0 && _liquidityFee == 0 && _burnFee == 0 && _walletFee == 0 && _buybackFee == 0) return;

    _prvTaxFee = _taxFee;
    _prvLiquidityFee = _liquidityFee;
    _prvBurnFee = _burnFee;
    _prvWalletFee = _walletFee;
    _prvBuybackFee = _buybackFee;

    _taxFee = 0;
    _liquidityFee = 0;
    _burnFee = 0;
    _walletFee = 0;
    _buybackFee = 0;
  }

  function restoreAllFee() private {
    _taxFee = _prvTaxFee;
    _liquidityFee = _prvLiquidityFee;
    _burnFee = _prvBurnFee;
    _walletFee = _prvWalletFee;
    _buybackFee = _prvBuybackFee;
  }

  function isExcludedFromFee(address account) public view returns(bool) {
    return _isExcludedFromFee[account];
  }

  function _approve(address owner, address spender, uint256 amount) private {
    require(owner != address(0), "from 0");
    require(spender != address(0), "to 0");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) private {
    require(from != address(0), "from 0");
    require(to != address(0),"to 0");
    require(amount > 0, "a = 0");


    if(from != this.getOwner() && to != this.getOwner()) {
      require(amount <= _maxTxAmount, "maxTX");
    }

    if(from != this.getOwner() && to != this.getOwner() && to != address(0) && to != dead && to != pcsV2Pair){
      uint256 contractBalanceRecepient = balanceOf(to);
      require(contractBalanceRecepient + amount <= _maxWalletAmount, "maxWA");
    }
    // is the token balance of this contract address over the min number of
    // tokens that we need to initiate a swap + liquidity lock?
    // also, don't get caught in a circular liquidity event.
    // also, don't swap & liquify if sender is uniswap pair.
    uint256 contractTokenBalance = balanceOf(address(this));

    if(contractTokenBalance >= _maxTxAmount)
    {
      contractTokenBalance = _maxTxAmount;
    }

    bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
    if (
      !inSwapAndLiquify &&
    to == pcsV2Pair &&
    swapAndLiquifyEnabled
    ) {
      if(overMinTokenBalance){
        contractTokenBalance = numTokensSellToAddToLiquidity;
        //add liquidity
        swapAndLiquify(contractTokenBalance);
      }
      if(_buybackFee !=0){
        uint256 balance = address(this).balance;
        if (balance > uint256(1 * 10**18)) {

          if (balance > buyBackUpperLimit)
            balance = buyBackUpperLimit;

          buyBackTokens(balance.div(100));
        }
      }
    }

    //indicates if fee should be deducted from transfer
    bool takeFee = true;

    //if any account belongs to _isExcludedFromFee account then remove the fee
    if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
      takeFee = false;
    }

    //transfer amount, it will take tax, burn, liquidity fee
    _tokenTransfer(from,to,amount,takeFee);
  }

  function burn(uint256 burnAmount) public {
    require(burnAmount >= 0, "zero");
    require(burnAmount <= _rOwned[msg.sender], "exceed");

    _rOwned[msg.sender] = _rOwned[msg.sender] - burnAmount;
    _tTotal = _tTotal - burnAmount;

    emit Transfer(msg.sender, address(0), burnAmount);
  }

  function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
    uint8 totFee  = _burnFee + _walletFee + _liquidityFee + _buybackFee;
    uint256 spentAmount = 0;
    uint256 totSpentAmount = 0;

    if(_burnFee != 0){
      spentAmount  = contractTokenBalance.div(totFee).mul(_burnFee);
      _tokenTransferNoFee(address(this), dead, spentAmount);
      totSpentAmount = spentAmount;
    }

    if(_walletFee != 0){
      spentAmount = contractTokenBalance.div(totFee).mul(_walletFee);
      _tokenTransferNoFee(address(this), feeWallet, spentAmount);
      totSpentAmount = totSpentAmount + spentAmount;
    }

    if(_buybackFee != 0){
      spentAmount = contractTokenBalance.div(totFee).mul(_buybackFee);
      swapTokensForBNB(spentAmount);
      totSpentAmount = totSpentAmount + spentAmount;
    }

    if(_liquidityFee != 0){
      contractTokenBalance = contractTokenBalance.sub(totSpentAmount);
      uint256 half = contractTokenBalance.div(2);
      uint256 otherHalf = contractTokenBalance.sub(half);
      uint256 initialBalance = address(this).balance;
      swapTokensForBNB(half);
      uint256 newBalance = address(this).balance.sub(initialBalance);
      addLiquidity(otherHalf, newBalance);
      emit SwapAndLiquify(half, newBalance, otherHalf);
    }
  }

  function buyBackTokens(uint256 amount) private lockTheSwap {
    if (amount > 0) {
      swapBNBForTokens(amount);
    }
  }

  function swapTokensForBNB(uint256 tokenAmount) private {
    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = pcsV2Router.WETH();

    _approve(address(this), address(pcsV2Router), tokenAmount);

    // make the swap
    pcsV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0, // accept any amount of ETH
      path,
      address(this),
      block.timestamp
    );
  }

  function swapBNBForTokens(uint256 amount) private {
    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = pcsV2Router.WETH();
    path[1] = address(this);

    // make the swap
    pcsV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
      0, // accept any amount of Tokens
      path,
      dead, // Burn address
      block.timestamp.add(300)
    );
  }

  function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    // approve token transfer to cover all possible scenarios
    _approve(address(this), address(pcsV2Router), tokenAmount);

    // add the liquidity
    pcsV2Router.addLiquidityETH{value: ethAmount}(
      address(this),
      tokenAmount,
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      dead,
      block.timestamp
    );
  }

  //this method is responsible for taking all fee, if takeFee is true
  function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
    if(!takeFee)
      removeAllFee();

    if (_isExcluded[sender] && !_isExcluded[recipient]) {
      _transferFromExcluded(sender, recipient, amount);
    } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
      _transferToExcluded(sender, recipient, amount);
    } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
      _transferStandard(sender, recipient, amount);
    } else if (_isExcluded[sender] && _isExcluded[recipient]) {
      _transferBothExcluded(sender, recipient, amount);
    } else {
      _transferStandard(sender, recipient, amount);
    }

    if(!takeFee)
      restoreAllFee();
  }

  function _transferStandard(address sender, address recipient, uint256 tAmount) private {
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _takeLiquidity(tLiquidity);
    _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
  }

  function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _takeLiquidity(tLiquidity);
    _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
  }

  function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
    _tOwned[sender] = _tOwned[sender].sub(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _takeLiquidity(tLiquidity);
    _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
  }

  function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
    _tOwned[sender] = _tOwned[sender].sub(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _takeLiquidity(tLiquidity);
    _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
  }

  function _tokenTransferNoFee(address sender, address recipient, uint256 amount) private {
    uint256 currentRate =  _getRate();
    uint256 rAmount = amount.mul(currentRate);

    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rAmount);

    if (_isExcluded[sender]) {
      _tOwned[sender] = _tOwned[sender].sub(amount);
    }
    if (_isExcluded[recipient]) {
      _tOwned[recipient] = _tOwned[recipient].add(amount);
    }
    emit Transfer(sender, recipient, amount);
  }

  function recoverBEP20(address tokenAddress, uint256 tokenAmount) public onlyOwner {
    // do not allow recovering self token
    require(tokenAddress != address(this), "Sw");
    IERC20(tokenAddress).transfer(this.getOwner(), tokenAmount);
  }
}
