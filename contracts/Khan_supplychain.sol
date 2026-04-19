// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MustafaSajidBlockchain {
    address public owner;

    enum Role {
        None,
        Manufacturer,
        Distributor,
        Retailer,
        Customer
    }

    enum Status {
        Manufactured,
        InTransit,
        Delivered
    }

    struct Product {
        uint256 id;
        string name;
        string description;
        address currentOwner;
        Status status;
        bool exists;
    }

    struct HistoryEntry {
        address holder;
        Role role;
        Status status;
        uint256 timestamp;
    }

    mapping(address => Role) public roles;
    mapping(uint256 => Product) public products;
    mapping(uint256 => HistoryEntry[]) private productHistory;

    uint256 public productCount;

    event RoleAssigned(address indexed account, Role indexed role);
    event ProductRegistered(uint256 indexed productId, address indexed manufacturer, string name);
    event ProductTransferred(
        uint256 indexed productId,
        address indexed from,
        address indexed to,
        Role fromRole,
        Role toRole,
        Status status
    );

    constructor() {
        owner = msg.sender;
        roles[msg.sender] = Role.Manufacturer;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

    modifier onlyRole(Role requiredRole) {
        require(roles[msg.sender] == requiredRole, "Unauthorized role");
        _;
    }

    modifier productExists(uint256 productId) {
        require(products[productId].exists, "Product does not exist");
        _;
    }

    function assignRole(address account, Role role) external onlyOwner {
        require(account != address(0), "Invalid account");
        require(role != Role.None, "Role cannot be None");

        roles[account] = role;
        emit RoleAssigned(account, role);
    }

    function registerProduct(
        string memory name,
        string memory description
    ) external onlyRole(Role.Manufacturer) {
        productCount++;

        products[productCount] = Product({
            id: productCount,
            name: name,
            description: description,
            currentOwner: msg.sender,
            status: Status.Manufactured,
            exists: true
        });

        productHistory[productCount].push(
            HistoryEntry({
                holder: msg.sender,
                role: roles[msg.sender],
                status: Status.Manufactured,
                timestamp: block.timestamp
            })
        );

        emit ProductRegistered(productCount, msg.sender, name);
    }

    function transferOwnership(
        uint256 productId,
        address newOwner
    ) external productExists(productId) {
        Product storage product = products[productId];
        require(product.currentOwner == msg.sender, "You do not own this product");

        Role senderRole = roles[msg.sender];
        Role newOwnerRole = roles[newOwner];

        require(_isValidTransfer(senderRole, newOwnerRole), "Invalid role transition");

        product.currentOwner = newOwner;
        product.status = newOwnerRole == Role.Customer ? Status.Delivered : Status.InTransit;

        productHistory[productId].push(
            HistoryEntry({
                holder: newOwner,
                role: newOwnerRole,
                status: product.status,
                timestamp: block.timestamp
            })
        );

        emit ProductTransferred(productId, msg.sender, newOwner, senderRole, newOwnerRole, product.status);
    }

    function getProductHistory(
        uint256 productId
    ) external view productExists(productId) returns (HistoryEntry[] memory) {
        return productHistory[productId];
    }

    function getProduct(uint256 productId) external view productExists(productId) returns (Product memory) {
        return products[productId];
    }

    function _isValidTransfer(Role fromRole, Role toRole) internal pure returns (bool) {
        if (fromRole == Role.Manufacturer && toRole == Role.Distributor) {
            return true;
        }

        if (fromRole == Role.Distributor && toRole == Role.Retailer) {
            return true;
        }

        if (fromRole == Role.Retailer && toRole == Role.Customer) {
            return true;
        }

        return false;
    }
}
