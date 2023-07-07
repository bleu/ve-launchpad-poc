// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/// @notice This cheat codes interface is named _CheatCodes so you can use the CheatCodes interface in other testing
/// files without errors
interface _CheatCodes {
    function ffi(string[] calldata) external returns (bytes memory);

    function getCode(string calldata) external returns (bytes memory);
}

contract DeploymentHelper {
    address private constant _HEVM_ADDRESS =
        address(bytes20(uint160(uint256(keccak256("hevm cheat code")))));

    _CheatCodes private cheatCodes = _CheatCodes(_HEVM_ADDRESS);

    ///@notice Compiles a Vyper contract and returns the address that the contract was deployeod to
    ///@notice If deployment fails, an error will be thrown
    ///@param fileName - The file name of the Vyper contract. For example, the file name for "Store.vy" is "Store"
    ///@return deployedAddress - The address that the contract was deployed to

    function deployVyperContract(
        string memory fileName
    ) public returns (address) {
        ///@notice create a list of strings with the commands necessary to compile Vyper contracts
        string[] memory cmds = new string[](2);
        cmds[0] = "vyper_compile";
        cmds[1] = string(abi.encodePacked("vyper_contracts/", fileName, ".vy"));

        bytes memory bytecode = cheatCodes.ffi(cmds);

        address deployedAddress;
        assembly {
            deployedAddress := create(0, add(bytecode, 0x20), mload(bytecode))
        }

        ///@notice check that the deployment was successful
        require(
            deployedAddress != address(0),
            "DeploymentHelper could not deploy contract"
        );

        ///@notice return the address that the contract was deployed to
        return deployedAddress;
    }

    ///@notice Compiles a Vyper contract w/ constructor arguments and returns the address the contract was deployed to
    ///@notice If deployment fails, an error will be thrown
    ///@param fileName - The file name of the Vyper contract. For example, the file name for "Store.vy" is "Store"
    ///@return deployedAddress - The address that the contract was deployed to
    function deployVyperContract(
        string memory fileName,
        bytes calldata args
    ) public returns (address) {
        ///@notice create a list of strings with the commands necessary to compile Vyper contracts
        string[] memory cmds = new string[](2);
        cmds[0] = "vyper_compile";
        cmds[1] = string(abi.encodePacked("vyper_contracts/", fileName, ".vy"));

        bytes memory _bytecode = cheatCodes.ffi(cmds);

        //add args to the deployment bytecode
        bytes memory bytecode = abi.encodePacked(_bytecode, args);

        address deployedAddress;
        assembly {
            deployedAddress := create(0, add(bytecode, 0x20), mload(bytecode))
        }

        ///@notice check that the deployment was successful
        require(
            deployedAddress != address(0),
            "DeploymentHelper could not deploy contract"
        );

        ///@notice return the address that the contract was deployed to
        return deployedAddress;
    }

    /// @dev Consider listening to the Blueprint if you haven't already
    /// @param fileName - The file name of the Blueprint Contract
    function deployVyperBlueprint(
        string memory fileName
    ) public returns (address) {
        ///@notice create a list of strings with the commands necessary to compile Vyper contracts
        string[] memory cmds = new string[](2);
        cmds[0] = "vyper";
        cmds[1] = string(abi.encodePacked("vyper_contracts/", fileName, ".vy"));

        bytes memory bytecode = cheatCodes.ffi(cmds);

        require(bytecode.length > 0, "Initcodes length must be greater than 0");

        bytes memory eip_5202_bytecode = bytes(
            abi.encodePacked(
                hex"fe", // EIP_5202_EXECUTION_HALT_BYTE
                hex"71", // EIP_5202_BLUEPRINT_IDENTIFIER_BYTE
                hex"00", // EIP_5202_VERSION_BYTE
                bytecode
            )
        );

        bytes2 len = bytes2(uint16(eip_5202_bytecode.length));

        bytes memory deployBytecode = bytes(
            abi.encodePacked(
                hex"61", // DEPLOY_PREAMBLE_INITIAL_BYTE
                len, // DEPLOY_PREAMBLE_BYTE_LENGTH
                hex"3d81600a3d39f3", // DEPLOY_PREABLE_POST_LENGTH_BYTES
                eip_5202_bytecode
            )
        );

        address deployedAddress;
        assembly {
            deployedAddress := create(
                0,
                add(deployBytecode, 0x20),
                mload(deployBytecode)
            )
        }

        require(
            deployedAddress != address(0),
            "DeploymentHelper could not deploy contract"
        );

        ///@notice return the address that the contract was deployed to
        return deployedAddress;
    }

    /// @dev Consider listening to the Blueprint if you haven't already
    /// @param contractName - The file name of the Blueprint Contract
    function deploySolidityBlueprint(
        string memory contractName
    ) public returns (address) {
        bytes memory bytecode = abi.encodePacked(
            cheatCodes.getCode(contractName)
        );

        require(bytecode.length > 0, "Initcodes length must be greater than 0");

        bytes memory eip_5202_bytecode = bytes(
            abi.encodePacked(
                hex"fe", // EIP_5202_EXECUTION_HALT_BYTE
                hex"71", // EIP_5202_BLUEPRINT_IDENTIFIER_BYTE
                hex"00", // EIP_5202_VERSION_BYTE
                bytecode
            )
        );

        bytes2 len = bytes2(uint16(eip_5202_bytecode.length));

        bytes memory deployBytecode = bytes(
            abi.encodePacked(
                hex"61", // DEPLOY_PREAMBLE_INITIAL_BYTE
                len, // DEPLOY_PREAMBLE_BYTE_LENGTH
                hex"3d81600a3d39f3", // DEPLOY_PREABLE_POST_LENGTH_BYTES
                eip_5202_bytecode
            )
        );

        address deployedAddress;
        assembly {
            deployedAddress := create(
                0,
                add(deployBytecode, 0x20),
                mload(deployBytecode)
            )
        }

        require(
            deployedAddress != address(0),
            "DeploymentHelper could not deploy contract"
        );

        ///@notice return the address that the contract was deployed to
        return deployedAddress;
    }
}
