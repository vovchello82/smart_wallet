// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

contract TokenManager {
    enum TokenStatus {
        Created,
        Paid,
        Used
    }

    struct S_AccessToken {
        bytes32 tokenValue;
    }

    address payable public immutable owner;
    S_AccessToken[] private tokens;
    uint public currentPriceInWei = 1 wei;

    mapping(address => bytes32[]) private tokensOf;

    event TokenEvent(bytes32 _token, uint _state, address indexed _issuer);

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    function getTokensOf() public view returns (bytes32[] memory) {
        return tokensOf[msg.sender];
    }

    function useLastTokenOf() external {
        require(tokensOf[msg.sender].length > 0, "no tokens to be used");
        bytes32 tokenBytes32 = tokensOf[msg.sender][
            tokensOf[msg.sender].length - 1
        ];
        tokensOf[msg.sender].pop();
        emit TokenEvent(tokenBytes32, uint(TokenStatus.Used), msg.sender);
    }

    function createToken(string calldata _token) public isOwner {
        require(bytes(_token).length < 32, "string mast be less then 32 chars");
        bytes32 tokenBytes32 = stringToBytes32(_token);
        tokens.push(S_AccessToken(tokenBytes32));
        emit TokenEvent(tokenBytes32, uint(TokenStatus.Created), msg.sender);
    }

    function updateCurrentPriceInWei(uint _newPrice) public isOwner {
        require(_newPrice > 0, "the new price must be > 0 ");
        currentPriceInWei = _newPrice;
    }

    function withdraw(uint _amount) external isOwner {
        require(_amount > 0, "withdrawal must be > 0");
        payable(owner).transfer(_amount);
    }

    function tokensAvaiable() public view returns (uint) {
        return tokens.length;
    }

    function buyToken() external payable {
        require(tokens.length > 0, "no tokens avaiable");
        require(msg.value >= currentPriceInWei, "not enough money sent");
        uint payback = msg.value - currentPriceInWei;

        bytes32 token = tokens[tokens.length - 1].tokenValue;
        tokensOf[msg.sender].push(token);
        tokens.pop();
        emit TokenEvent(token, uint(TokenStatus.Paid), msg.sender);
        payable(msg.sender).transfer(payback);
    }

    function stringToBytes32(
        string memory source
    ) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
}
