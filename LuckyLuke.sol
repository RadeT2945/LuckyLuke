// This is deflationary project. Each LUCKY transaction triggers a burn rate of 2%. 
// Token rewards its holders with a 3% tax on each transaction.
// Each transaction will also add 5% to the SushiSwap liquidity for a better trading experience.

/*
▄▄▌  ▄• ▄▌ ▄▄· ▄ •▄  ▄· ▄▌  ▄▄▌  ▄• ▄▌▄ •▄ ▄▄▄ .  ·▄▄▄▪   ▐ ▄  ▄▄▄·  ▐ ▄  ▄▄· ▄▄▄ .  ▄▄▄ . ▄▄·       .▄▄ ·  ▄· ▄▌.▄▄ · ▄▄▄▄▄▄▄▄ .• ▌ ▄ ·. 
██•  █▪██▌▐█ ▌▪█▌▄▌▪▐█▪██▌  ██•  █▪██▌█▌▄▌▪▀▄.▀·  ▐▄▄·██ •█▌▐█▐█ ▀█ •█▌▐█▐█ ▌▪▀▄.▀·  ▀▄.▀·▐█ ▌▪ ▄█▀▄ ▐█ ▀. ▐█▪██▌▐█ ▀. •██  ▀▄.▀··██ ▐███▪
██▪  █▌▐█▌██ ▄▄▐▀▀▄·▐█▌▐█▪  ██▪  █▌▐█▌▐▀▀▄·▐▀▀▪▄  ██▪ ▐█·▐█▐▐▌▄█▀▀█ ▐█▐▐▌██ ▄▄▐▀▀▪▄  ▐▀▀▪▄██ ▄▄▐█▌.▐▌▄▀▀▀█▄▐█▌▐█▪▄▀▀▀█▄ ▐█.▪▐▀▀▪▄▐█ ▌▐▌▐█·
▐█▌▐▌▐█▄█▌▐███▌▐█.█▌ ▐█▀·.  ▐█▌▐▌▐█▄█▌▐█.█▌▐█▄▄▌  ██▌.▐█▌██▐█▌▐█ ▪▐▌██▐█▌▐███▌▐█▄▄▌  ▐█▄▄▌▐███▌▐█▌.▐▌▐█▄▪▐█ ▐█▀·.▐█▄▪▐█ ▐█▌·▐█▄▄▌██ ██▌▐█▌
.▀▀▀  ▀▀▀ ·▀▀▀ ·▀  ▀  ▀ •   .▀▀▀  ▀▀▀ ·▀  ▀ ▀▀▀   ▀▀▀ ▀▀▀▀▀ █▪ ▀  ▀ ▀▀ █▪·▀▀▀  ▀▀▀    ▀▀▀ ·▀▀▀  ▀█▄▀▪ ▀▀▀▀   ▀ •  ▀▀▀▀  ▀▀▀  ▀▀▀ ▀▀  █▪▀▀▀

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20Deflationary.sol";

contract LuckyLuke is ERC20Deflationary {
    constructor() ERC20Deflationary("LuckyLuke", "LUCKY", 9, 7777777) {
        
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";


contract ERC20Deflationary is Context, IERC20, Ownable {
    // balances for address that are included.
    mapping (address => uint256) private _rBalances;
    // balances for address that are excluded.
    mapping (address => uint256) private _tBalances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromReward;
    address[] private _excludedFromReward;
   
    uint8 private immutable _decimals;
    uint256 private  _totalSupply;
    uint256 private _currentSupply;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;

    // this percent of transaction amount that will be burnt.
    uint8 private _taxFeeBurn;
    // percent of transaction amount that will be redistribute to all holders.
    uint8 private _taxFeeReward;
    // percent of transaction amount that will be added to the liquidity pool
    uint8 private _taxFeeLiquidity; 

    string private _name;
    string private _symbol;

    address private constant burnAccount = 0x000000000000000000000000000000000000dEaD;

    event Burn(address from, uint256 amount);

    

    constructor (string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        // Sets the values for `name`, `symbol`, `totalSupply`, `taxFeeBurn`, `taxFeeReward`, and `taxFeeLiquidity`.
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * (10**decimals_);
        _currentSupply = _totalSupply;
        _rTotal = (~uint256(0) - (~uint256(0) % _totalSupply));

        // mint
        _rBalances[_msgSender()] = _rTotal;

        // exclude owner and this contract from fee.
        _excludeFromFee(owner());
        _excludeFromFee(address(this));

        // exclude owner and burnAccount from receiving rewards.
        excludeAccountFromReward(owner());
        excludeAccountFromReward(burnAccount);
        
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function taxFeeBurn() public view virtual returns (uint8) {
        return _taxFeeBurn;
    }

    function taxFeeReward() public view virtual returns (uint8) {
        return _taxFeeReward;
    }

    function taxFeeLiquidity() public view virtual returns (uint8) {
        return _taxFeeLiquidity;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function currentSupply() public view virtual returns (uint256) {
        return _currentSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        if (_isExcludedFromReward[account]) return _tBalances[account];
        return tokenFromReflection(_rBalances[account]);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        require(_allowances[sender][_msgSender()] >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender]+addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != burnAccount, "ERC20: burn from the burn address");

        uint256 accountBalance = balanceOf(account);
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

        uint256 rAmount = _getRValuesWithoutFee(amount);

        if (isExcluded(account)) {
            _tBalances[account] -= amount;
            _rBalances[account] -= rAmount;
        } else {
            _rBalances[account] -= rAmount;
        }

        _tBalances[burnAccount] += amount;
        _rBalances[burnAccount] += rAmount;

        // decrease the current coin supply
        _currentSupply -= amount;

        emit Burn(account, amount);
        emit Transfer(account, burnAccount, amount);
    }
   
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcludedFromReward[account];
    }

    function totalFees() public view virtual returns (uint256) {
        return _tFeeTotal;
    }

    /**
     * @dev Distribute tokens to all holders that are included from reward. 
     *
     *  Requirements:
     * - the caller must have a balance of at least `amount`.
     */
    function distribute(uint256 amount) public {
        address sender = _msgSender();
        require(!_isExcludedFromReward[sender], "Excluded addresses cannot call this function");
        ValuesFromAmount memory values = _getValues(amount, false);
        _rBalances[sender] = _rBalances[sender] - values.rAmount;
        _rTotal = _rTotal - values.rAmount;
        _tFeeTotal = _tFeeTotal + amount ;
    }

    // todo: figure out what this does.
    function reflectionFromToken(uint256 amount, bool deductTransferFee) public view returns(uint256) {
        require(amount <= _totalSupply, "Amount must be less than supply");
        ValuesFromAmount memory values = _getValues(amount, deductTransferFee);
        return values.rTransferAmount;
    }

    /**
        Used to figure out the balance of rBalance.
     */
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount / currentRate;
    }

    
    function _excludeFromFee(address account) private onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function _includeInFee(address account) private onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function excludeAccountFromReward(address account) public onlyOwner {
        require(!_isExcludedFromReward[account], "Account is already excluded");
        if(_rBalances[account] > 0) {
            _tBalances[account] = tokenFromReflection(_rBalances[account]);
        }
        _isExcludedFromReward[account] = true;
        _excludedFromReward.push(account);
    }

    function includeAccountFromReward(address account) public onlyOwner {
        require(_isExcludedFromReward[account], "Account is already included");
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (_excludedFromReward[i] == account) {
                _excludedFromReward[i] = _excludedFromReward[_excludedFromReward.length - 1];
                _tBalances[account] = 0;
                _isExcludedFromReward[account] = false;
                _excludedFromReward.pop();
                break;
            }
        }
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        ValuesFromAmount memory values = _getValues(amount, _isExcludedFromFee[sender]);
        
        if (_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            _transferFromExcluded(sender, recipient, values);
        } else if (!_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferToExcluded(sender, recipient, values);
        } else if (!_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            _transferStandard(sender, recipient, values);
        } else if (_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferBothExcluded(sender, recipient, values);
        } else {
            _transferStandard(sender, recipient, values);
        }

        _afterTokenTransfer(values);

    }


    /**
     * burns
     * reflect
     * add liquidity

        tValues = (uint256 tTransferAmount, uint256 tBurnFee, uint256 tRewardFee, uint256 tLiquidityFee);
        rValues = uint256 rAmount, uint256 rTransferAmount, uint256 rBurnFee, uint256 rRewardFee, uint256 rLiquidityFee;
     */
    function _afterTokenTransfer(ValuesFromAmount memory values) internal virtual {
        // burn from contract address
        burn(values.tBurnFee);
        
        // reflect
        _distributeFee(values.rRewardFee, values.tRewardFee);

        // todo: add liquidity
     }

    
    function _transferStandard(address sender, address recipient, ValuesFromAmount memory values) private {
        
    
        _rBalances[sender] = _rBalances[sender] - values.rAmount;
        _rBalances[recipient] = _rBalances[recipient] + values.rTransferAmount;   

        emit Transfer(sender, recipient, values.tTransferAmount);
    }

    
    function _transferToExcluded(address sender, address recipient, ValuesFromAmount memory values) private {
        
        _rBalances[sender] = _rBalances[sender] - values.rAmount;
        _tBalances[recipient] = _tBalances[recipient] + values.tTransferAmount;
        _rBalances[recipient] = _rBalances[recipient] + values.rTransferAmount;    

        _afterTokenTransfer(values);
        
        emit Transfer(sender, recipient, values.tTransferAmount);
    }

    
    function _transferFromExcluded(address sender, address recipient, ValuesFromAmount memory values) private {
        
        _tBalances[sender] = _tBalances[sender] - values.amount;
        _rBalances[sender] = _rBalances[sender] - values.rAmount;
        _rBalances[recipient] = _rBalances[recipient] + values.rTransferAmount;   

        _afterTokenTransfer(values);

        emit Transfer(sender, recipient, values.tTransferAmount);
    }

    
    function _transferBothExcluded(address sender, address recipient, ValuesFromAmount memory values) private {

        _tBalances[sender] = _tBalances[sender] - values.amount;
        _rBalances[sender] = _rBalances[sender] - values.rAmount;
        _tBalances[recipient] = _tBalances[recipient] + values.tTransferAmount;
        _rBalances[recipient] = _rBalances[recipient] + values.rTransferAmount;        

        _afterTokenTransfer(values);
        
        emit Transfer(sender, recipient, values.tTransferAmount);
    }

    function _distributeFee(uint256 rFee, uint256 tFee) private {
        // to decrease rate thus increase amount reward receive.
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }
    
    struct ValuesFromAmount {
        uint256 amount;
        uint256 tBurnFee;
        uint256 tRewardFee;
        uint256 tLiquidityFee;
        // amount after fee
        uint256 tTransferAmount;

        uint256 rAmount;
        uint256 rBurnFee;
        uint256 rRewardFee;
        uint256 rLiquidityFee;
        uint256 rTransferAmount;
    }
   
    function _getValues(uint256 amount, bool deductTransferFee) private view returns (ValuesFromAmount memory) {
        ValuesFromAmount memory values;
        values.amount = amount;
        _getTValues(values, deductTransferFee);
        _getRValues(values, deductTransferFee);
        return values;
    }

    function _getTValues(ValuesFromAmount memory values, bool deductTransferFee) view private {
        
        if (deductTransferFee) {
            values.tTransferAmount = values.amount;
        } else {
            // calculate fee
            values.tBurnFee = _calculateTaxFeeBurn(values.amount);
            values.tRewardFee = _calculateTaxFeeReward(values.amount);
            values.tLiquidityFee = _calculateTaxFeeLiquidity(values.amount);
            
            // amount after fee
            values.tTransferAmount = values.amount - values.tBurnFee - values.tRewardFee - values.tLiquidityFee;
        }
        
    }

    function _getRValues(ValuesFromAmount memory values, bool deductTransferFee) view private {
        uint256 currentRate = _getRate();

        values.rAmount = values.amount * currentRate;

        if (deductTransferFee) {
            values.rTransferAmount = values.rAmount;
        } else {
            values.rAmount = values.amount * currentRate;
            values.rBurnFee = values.tBurnFee * currentRate;
            values.rRewardFee = values.tRewardFee * currentRate;
            values.rLiquidityFee = values.tLiquidityFee * currentRate;
            values.rTransferAmount = values.rAmount - values.rBurnFee - values.rRewardFee - values.rLiquidityFee;
        }
        
    }

    function _getRValuesWithoutFee(uint256 amount) private view returns (uint256) {
        uint256 currentRate = _getRate();
        return amount * currentRate;
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _totalSupply;      
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (_rBalances[_excludedFromReward[i]] > rSupply || _tBalances[_excludedFromReward[i]] > tSupply) return (_rTotal, _totalSupply);
            rSupply = rSupply - _rBalances[_excludedFromReward[i]];
            tSupply = tSupply - _tBalances[_excludedFromReward[i]];
        }
        if (rSupply < _rTotal / _totalSupply) return (_rTotal, _totalSupply);
        return (rSupply, tSupply);
    }

    function setTaxFeeBurn(uint8 taxFeeBurn_) public onlyOwner {
        require(taxFeeBurn_ + _taxFeeReward + _taxFeeLiquidity < 100, "Tax fee too high.");
        _taxFeeBurn = taxFeeBurn_;
    }

    function setTaxFeeReward(uint8 taxFeeReward_) public onlyOwner {
        require(_taxFeeBurn + taxFeeReward_ + _taxFeeLiquidity < 100, "Tax fee too high.");
        _taxFeeReward = taxFeeReward_;
    }

    function setTaxFeeLiquidity(uint8 taxFeeLiquidity_) public onlyOwner {
        require(_taxFeeBurn + _taxFeeReward + taxFeeLiquidity_ < 100, "Tax fee too high.");
        _taxFeeLiquidity = taxFeeLiquidity_;
    }

    function _calculateTaxFeeBurn(uint256 amount) private view returns (uint256) {
        return amount * _taxFeeBurn / (10**2);
    }

    function _calculateTaxFeeReward(uint256 amount) private view returns (uint256) {
        return amount * _taxFeeReward / (10**2);
    } 

    function _calculateTaxFeeLiquidity(uint256 amount) private view returns (uint256) {
        return amount * _taxFeeLiquidity / (10**2);
    }

}
// A copy of https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
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
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
// A copy of https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
