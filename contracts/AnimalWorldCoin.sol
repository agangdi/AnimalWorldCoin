pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract ERC20Token is ERC20Interface{
    
    using SafeMath for uint;
    
    address public owner;
    string public constant name = "Animal World Coin";
    string public constant symbol = "AWC";
    uint8 public constant decimals = 0;  // 18 is the most common number of decimal places
    uint _totalSupply;

    event Transfer(address sender, uint value);
    
    // fallback
    function () public payable{
        emit Transfer(msg.sender, msg.value);
    }
    
    // Balances for each account
    mapping(address => uint256) balances;
 
    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) allowed;

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public payable {
        owner = msg.sender;
        _totalSupply = 2100000000;
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }
    
    // Get the token balance for account `tokenOwner`
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }
 
    // Transfer the balance from owner's account to another account
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
 
    // Send `tokens` amount of tokens from address `from` to address `to`
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

}

contract AnimalWorldCoin is ERC20Token{
    
    enum Result{Win, Lose, Draw}
    
    uint private rate;  // the rate of AWC vs wei
    uint private price;  // token amount of per Punches
    
    struct Punches{
        address sender;
        int8 push;  // 0 rock 1 paper 2 scissors
        uint created;  // the timestamp of punches
        address competitor; //
        Result res;
        bool battled; // is this puches battled
    }
    
    // account's puch list
    mapping(address => Punches[]) private PunchList;
    Punches private lastPunches; // last puches must be private variable
    
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public payable {
        owner = msg.sender;
        _totalSupply = 2100000000;
        rate = 100000000000000;
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
        price = 100;
        // init last Punches with rock
        lastPunches = initPushes(0);
    }
    
    function() public payable{
        fetchAWC();
        emit Transfer(msg.sender, msg.value);
    }
    
    // init push
    function initPushes(int8 a) private view returns(Punches p){
        p.sender = msg.sender;
        p.push = a;
        p.created = now;
        p.battled = false;
    }
    
    // letPunches
    function letPunches(int8 push) public payable returns(bool success){
        if (!validatePush(push)) return false;
        require(balances[msg.sender] >= price);
        Punches memory curPunches = initPushes(push);
        balances[msg.sender] = balances[msg.sender].sub(price);
        if (lastPunches.battled) {
            lastPunches = curPunches;
            return true;
        }
        // battle
        Result res = battle(curPunches.push, lastPunches.push);
        if (res == Result.Win){
            balances[curPunches.sender] += price * 2;
        }
        if (res == Result.Draw){
            balances[curPunches.sender] += price;
            balances[lastPunches.sender] += price;
        }
        if (res == Result.Lose){
            balances[lastPunches.sender] += price * 2;
        }
        lastPunches.battled = true;
        return true;
    }
    
    // validate push
    function validatePush(int8 push) private pure returns(bool){
        return push >= 0 && push <= 2;
    }
    
    // battle
    function battle(int8 a, int8 b) private pure returns(Result) {
        if (a == b) {
            return Result.Draw;
        }
        int8 res = a-b;
        if (res == 1 || res == -2) {
           return Result.Win;
        }else{
            return Result.Lose;
        }
    }
    
    function fetchAWC() internal {
        uint amount = countTokenAmount();
        require(amount > 0);
        owner.transfer(msg.value);
        require(balances[owner] > amount);
        transferFrom(owner, msg.sender, amount);
    }
    
    function countTokenAmount() internal view returns (uint256){
        return msg.value.div(rate);
    }
    
    function myBalance() public view returns(uint){
        return balances[msg.sender];
    }
    
    function setPrice(uint p) public payable returns(bool){
        require(owner == msg.sender);
        price = p;
        return true;
    }
    
    function getPrice() public view returns(uint p){
        return price;
    }
    
}
