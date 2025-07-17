// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ViexProofVerifier is Ownable {
    // Scalar field size
    uint256 constant r =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;
    // Base field size
    uint256 constant q =
        21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // Verification Key data
    uint256 constant alphax =
        9388481328254321963844482555285281080530289693043045865234067462026832499985;
    uint256 constant alphay =
        12171046506718115549533501616101980287175377064184303304053549106317456478273;
    uint256 constant betax1 =
        13995647858685191875399108554059960905020265903214412290457079862911112768252;
    uint256 constant betax2 =
        17233075462434330120970005520520640208571351305012446930939552968245092560929;
    uint256 constant betay1 =
        11452005801120938367901611583528324040399212301919881278449395065650749941177;
    uint256 constant betay2 =
        10327219521609611785636631899781251539494587908927830217634173796314242921339;
    uint256 constant gammax1 =
        11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 constant gammax2 =
        10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 constant gammay1 =
        4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 constant gammay2 =
        8495653923123431417604973247489272438418190587263600148770280649306958101930;
    uint256 constant deltax1 =
        11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 constant deltax2 =
        10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 constant deltay1 =
        4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 constant deltay2 =
        8495653923123431417604973247489272438418190587263600148770280649306958101930;

    uint256 constant IC0x =
        12986148404023457460261392003293966028067294727564659465488165541932816005735;
    uint256 constant IC0y =
        9275728756469294026818464113174507079930555766049119635740279100484390519140;

    uint256 constant IC1x =
        10729784135155736091494097785752734055068868489437741583311461553666900159156;
    uint256 constant IC1y =
        4967819738778168853013088392759167788419931387647730664010399044006153295144;

    uint256 constant IC2x =
        19852539304623685913273209897502037605665932960364528494534968104053292880024;
    uint256 constant IC2y =
        5410206614585850044047598647086752591203621179919940490560150636079903716701;

    // Memory data
    uint16 constant pVk = 0;
    uint16 constant pPairing = 128;
    uint16 constant pLastMem = 896;

    /**
     * @dev Custom data type
     */
    struct AccountAddressInfo {
        string hashId;
        address account;
    }

    struct AccountHashInfo {
        address account;
        string accHash;
    }

    struct UpdateAccountInfo {
        string hashId;
        address oldAccount;
        address newAccount;
        string newAccountHash;
    }

    /**
     * @dev Custom state data
     */
    // accountHash: hash of the account address, eg: 0xabc... => 897654321
    mapping(address => string) public accountHash;
    // accountAddress: account address, eg: 897654321 => 0xabc...
    mapping(string => address) public accountAddress;
    // whitelistAddress: whitelist address, eg: 0xabc... => true
    mapping(address => bool) public whitelistAddress;
    // isAuthorizeVerify: true if we want to authorize caller of this function
    // false then anyone can call this function
    bool public isAuthorizeVerify;

    /**
     * @dev Constructor
     */
    constructor() Ownable(msg.sender) {
        // default is false
        isAuthorizeVerify = false;
    }

    /**
     * @dev Add an address to the whitelist
     * @param _address: address to add to the whitelist
     */
    function addWhitelistAddress(address _address) public {
        // check if the caller has authorization
        require(msg.sender == owner(), "Not authorized");

        // check if the address is already in the whitelist
        require(!whitelistAddress[_address], "Address already in whitelist");

        // add the address to the whitelist
        whitelistAddress[_address] = true;
    }

    /**
     * @dev Remove an address from the whitelist
     * @param _address: address to remove from the whitelist
     */
    function removeWhitelistAddress(address _address) public {
        // check if the caller has authorization
        require(msg.sender == owner(), "Not authorized");

        // check if the address is in the whitelist
        require(whitelistAddress[_address], "Address not in whitelist");

        // remove the address from the whitelist
        whitelistAddress[_address] = false;
    }

    /**
     * @dev Set the account address of hash
     * @param _info: array of AccountAddressInfo
     */
    function setAccountAddress(AccountAddressInfo[] memory _info) public {
        // check if the caller has authorization
        require(
            msg.sender == owner() || whitelistAddress[msg.sender],
            "Not authorized"
        );

        // set the account address
        for (uint256 i = 0; i < _info.length; i++) {
            accountAddress[_info[i].hashId] = _info[i].account;
        }
    }

    /**
     * @dev Remove the account address of hash
     * @param _hashes: array of hashes to remove the account address of
     */
    function removeAccountAddress(string[] memory _hashes) public {
        // check if the caller has authorization
        require(
            msg.sender == owner() || whitelistAddress[msg.sender],
            "Not authorized"
        );

        // remove the account address
        for (uint256 i = 0; i < _hashes.length; i++) {
            delete accountAddress[_hashes[i]];
        }
    }

    /**
     * @dev Set the account hash of an address
     * @param _infos: array of AccountHashInfo
     */
    function setAccountHash(AccountHashInfo[] memory _infos) public {
        // check if the caller has authorization
        require(
            msg.sender == owner() || whitelistAddress[msg.sender],
            "Not authorized"
        );

        // set the account hash
        for (uint256 i = 0; i < _infos.length; i++) {
            accountHash[_infos[i].account] = _infos[i].accHash;
        }
    }

    /**
     * @dev Remove the account hash of an address
     * @param _accounts: array of accounts to remove the account hash of
     */
    function removeAccountHash(address[] memory _accounts) public {
        // check if the caller has authorization
        require(
            msg.sender == owner() || whitelistAddress[msg.sender],
            "Not authorized"
        );

        // remove the account hash
        for (uint256 i = 0; i < _accounts.length; i++) {
            delete accountHash[_accounts[i]];
        }
    }

    /**
     * @dev Update the account address of hash
     * @param _infos: array of UpdateAccountInfo
     */
    function updateAccount(UpdateAccountInfo[] memory _infos) public {
        // check if the caller has authorization
        require(
            msg.sender == owner() || whitelistAddress[msg.sender],
            "Not authorized"
        );

        // update the account address
        for (uint256 i = 0; i < _infos.length; i++) {
            // remove old account state
            delete accountAddress[_infos[i].hashId];
            delete accountHash[_infos[i].oldAccount];

            // set new account state
            accountAddress[_infos[i].hashId] = _infos[i].newAccount;
            accountHash[_infos[i].newAccount] = _infos[i].newAccountHash;
        }
    }

    /**
     * @dev Verify a proof
     * @param _pA: proof A
     * @param _pB: proof B
     * @param _pC: proof C
     * @param _pubSignals: public signals
     * @return bool: true if the proof is valid, false otherwise
     */
    function verifyProof(
        uint[2] calldata _pA,
        uint[2][2] calldata _pB,
        uint[2] calldata _pC,
        uint[2] calldata _pubSignals
    ) public view returns (bool) {
        if (isAuthorizeVerify) {
            // check if the caller has authorization
            require(
                msg.sender == owner() || whitelistAddress[msg.sender],
                "Not authorized"
            );
        }

        address acc = address(uint160(uint256(_pubSignals[0])));
        uint256 accHash = stringToUint(accountHash[acc]);

        // compare public signal hash and account hash
        if (accHash != _pubSignals[1]) {
            return false;
        }

        assembly {
            function checkField(v) {
                if iszero(lt(v, r)) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }

            // G1 function to multiply a G1 value(x,y) to value in an address
            function g1_mulAccC(pR, x, y, s) {
                let success
                let mIn := mload(0x40)
                mstore(mIn, x)
                mstore(add(mIn, 32), y)
                mstore(add(mIn, 64), s)

                success := staticcall(sub(gas(), 2000), 7, mIn, 96, mIn, 64)

                if iszero(success) {
                    mstore(0, 0)
                    return(0, 0x20)
                }

                mstore(add(mIn, 64), mload(pR))
                mstore(add(mIn, 96), mload(add(pR, 32)))

                success := staticcall(sub(gas(), 2000), 6, mIn, 128, pR, 64)

                if iszero(success) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }

            function checkPairing(pA, pB, pC, pubSignals, pMem) -> isOk {
                let _pPairing := add(pMem, pPairing)
                let _pVk := add(pMem, pVk)

                mstore(_pVk, IC0x)
                mstore(add(_pVk, 32), IC0y)

                // Compute the linear combination vk_x
                g1_mulAccC(_pVk, IC1x, IC1y, calldataload(add(pubSignals, 0)))
                g1_mulAccC(_pVk, IC2x, IC2y, calldataload(add(pubSignals, 32)))

                // -A
                mstore(_pPairing, calldataload(pA))
                mstore(
                    add(_pPairing, 32),
                    mod(sub(q, calldataload(add(pA, 32))), q)
                )

                // B
                mstore(add(_pPairing, 64), calldataload(pB))
                mstore(add(_pPairing, 96), calldataload(add(pB, 32)))
                mstore(add(_pPairing, 128), calldataload(add(pB, 64)))
                mstore(add(_pPairing, 160), calldataload(add(pB, 96)))

                // alpha1
                mstore(add(_pPairing, 192), alphax)
                mstore(add(_pPairing, 224), alphay)

                // beta2
                mstore(add(_pPairing, 256), betax1)
                mstore(add(_pPairing, 288), betax2)
                mstore(add(_pPairing, 320), betay1)
                mstore(add(_pPairing, 352), betay2)

                // vk_x
                mstore(add(_pPairing, 384), mload(add(pMem, pVk)))
                mstore(add(_pPairing, 416), mload(add(pMem, add(pVk, 32))))

                // gamma2
                mstore(add(_pPairing, 448), gammax1)
                mstore(add(_pPairing, 480), gammax2)
                mstore(add(_pPairing, 512), gammay1)
                mstore(add(_pPairing, 544), gammay2)

                // C
                mstore(add(_pPairing, 576), calldataload(pC))
                mstore(add(_pPairing, 608), calldataload(add(pC, 32)))

                // delta2
                mstore(add(_pPairing, 640), deltax1)
                mstore(add(_pPairing, 672), deltax2)
                mstore(add(_pPairing, 704), deltay1)
                mstore(add(_pPairing, 736), deltay2)

                let success := staticcall(
                    sub(gas(), 2000),
                    8,
                    _pPairing,
                    768,
                    _pPairing,
                    0x20
                )

                isOk := and(success, mload(_pPairing))
            }

            let pMem := mload(0x40)
            mstore(0x40, add(pMem, pLastMem))

            // Validate that all evaluations ∈ F
            checkField(calldataload(add(_pubSignals, 0)))
            checkField(calldataload(add(_pubSignals, 32)))

            // Validate all evaluations
            let isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem)

            mstore(0, isValid)
            return(0, 0x20)
        }
    }

    function stringToUint(string memory str) private pure returns (uint256) {
        bytes memory bStr = bytes(str);
        uint256 result = 0;

        for (uint256 i = 0; i < bStr.length; i++) {
            // Check that character is between '0' and '9'
            require(bStr[i] >= 0x30 && bStr[i] <= 0x39, "Invalid character");
            result = result * 10 + (uint8(bStr[i]) - 48); // 0x30 == '0'
        }

        return result;
    }
}
