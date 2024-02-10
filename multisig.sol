// SPDX-License-Identifier: GPL-3.0


pragma solidity >=0.8.2 <0.9.0;

contract MultiSig {
    address[] public owners;
    uint public signaturesRequired;

    struct Transaction {
     address destination; // 트랜잭션의 목적지 주소
        uint value; // 전송할 이더의 양
        bytes data; // 트랜잭션 데이터
        bool executed; // 트랜잭션이 실행되었는지 여부
        uint signatureCount; // 서명된 수
    }

    mapping(uint => Transaction) public transactions;
    mapping(uint => mapping(address => bool)) public isSigned;
    uint public transactionCount;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not owner");
        _;
    }

    constructor(address[] memory _owners, uint _signaturesRequired) {
        require(_owners.length <= 5, "Cannot have more than 5 owners"); //5 명 지정 
        require(_signaturesRequired >= 3 && _signaturesRequired <= _owners.length, "Invalid number of required signatures"); //3명 이상

        for (uint i = 0; i < _owners.length; i++) {
            require(_owners[i] != address(0), "Invalid owner");
            owners.push(_owners[i]);
        }
        signaturesRequired = _signaturesRequired;
    }

    function submitTransaction(address destination, uint value, bytes memory data) public onlyOwner {
        uint txIndex = transactionCount;
        transactions[txIndex] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false,
            signatureCount: 0
        });
        transactionCount++;
    }

    function signTransaction(uint transactionId) public onlyOwner {
        Transaction storage transaction = transactions[transactionId];
        require(!transaction.executed, "Transaction already executed");
        require(!isSigned[transactionId][msg.sender], "Transaction already signed");

        transaction.signatureCount++;
        isSigned[transactionId][msg.sender] = true;

        if (transaction.signatureCount >= signaturesRequired) {
            executeTransaction(transactionId);
        }
    }

    function executeTransaction(uint transactionId) internal {
        Transaction storage transaction = transactions[transactionId];
        require(transaction.signatureCount >= signaturesRequired, "Insufficient signatures");
        require(!transaction.executed, "Transaction already executed");

        transaction.executed = true;
        (bool success, ) = transaction.destination.call{value: transaction.value}(transaction.data);
        require(success, "Transaction failed");
    }
}
