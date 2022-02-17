// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MultiSigWallet {
    uint256 public maxOwnerCount = 20;
    uint256 public approveCount = 11;

    event Confirmation(address indexed sender, uint256 indexed transactionId);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event Revocation(address indexed sender, uint256 indexed transactionId);
    event Submission(uint256 indexed transactionId);
    event Execution(uint256 indexed transactionId);
    event Deposit(address indexed sender, uint256 value);

    struct Transaction {
        address destination;
        uint256 value;
        bytes data;
        bool executed;
    }

    mapping(address => bool) public ownerMapping;
    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;
    address[] public owners;

    modifier onlyWallet() {
        require(msg.sender == address(this), "Not the wallet");
        _;
    }

    modifier onlyOwner() {
        require(ownerMapping[msg.sender], "Not an owner");
        _;
    }

    modifier notExecuted(uint256 transactionId) {
        require(
            !transactions[transactionId].executed,
            "Transaction is executed"
        );
        _;
    }

    modifier exists(uint256 transactionId) {
        require(transactionId < transactions.length, "Does not exists");
        _;
    }

    constructor(uint256 _max_owner_count, address[] memory _owners) {
        require(_max_owner_count > 0, "Owner count must me greater ther 0");
        require(_owners.length > 0, "Empty owners not allowed");

        maxOwnerCount = _max_owner_count;

        for (uint256 i = 0; i < _owners.length; i++) {
            if (!ownerMapping[_owners[i]] || _owners[i] == address(0)) revert();
            ownerMapping[_owners[i]] = true;
        }
        owners = _owners;
    }

    function addNewOwner(address owner) public onlyOwner {
        require(!ownerMapping[owner], "Already an owner");
        require(owner != address(0), "Not an empty address");
        require(owners.length < maxOwnerCount, "Owner overflow");

        ownerMapping[owner] = true;
        owners.push(owner);
        emit OwnerAddition(owner);
    }

    function removeOwner(address owner) public onlyWallet {
        require(owner != address(0), "Not empty address");
        require(ownerMapping[owner], "Not an owner");

        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        }
        ownerMapping[owner] = false;

        emit OwnerRemoval(owner);
    }

    function submitTransaction(
        address destination,
        uint256 value,
        bytes memory data
    ) public onlyOwner returns (uint256 transactionId) {
        require(destination != address(0), "Address not allowed");

        transactionId = transactions.length;
        transactions.push(Transaction(destination, value, data, false));

        emit Submission(transactionId);
    }

    function getConfirmationCount(uint256 transactionId)
        public
        view
        returns (uint256 transactionCount)
    {
        require(
            transactionId < transactions.length,
            "Transaction does not exists"
        );

        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) transactionCount = 1;
        }
    }

    function getTransactionsCount() public view returns (uint256) {
        return transactions.length;
    }

    function executeTransaction(uint256 transactionId)
        public
        exists(transactionId)
        notExecuted(transactionId)
    {
        Transaction memory transaction = transactions[transactionId];
        require(_isConfermed(transactionId), "Not confirmed");
        require(
            transaction.value <= address(this).balance,
            "Wallet balance owersized"
        );

        transactions[transactionId].executed = true;

        (bool success, ) = transaction.destination.call{
            value: transaction.value
        }(transaction.data);
        require(success, "Call function failed");
    }

    function _isConfermed(uint256 transactionId) internal view returns (bool) {
        uint256 confNumber = getConfirmationCount(transactionId);
        return confNumber >= approveCount;
    }

    function transactionVote(uint256 transactionId, bool confirmation)
        public
        onlyOwner
        exists(transactionId)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = confirmation;
        emit Confirmation(msg.sender, transactionId);
    }

}
