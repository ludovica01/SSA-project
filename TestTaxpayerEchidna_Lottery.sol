// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "Taxpayer.sol";



contract TestHardness_Lottery {

    Lottery public lot;
    Taxpayer public tp;

    address owner = address(this);

    constructor() {
        // deploy Lottery with period 10
        lot = new Lottery(10);
        lot.startLottery();

        // deploy taxpayer where this contract is the owner
        tp = new Taxpayer(address(0), address(0));
    }



   function echidna_commit_sets_rev_and_flags() public returns (bool) {
    uint256 r = uint256(keccak256(abi.encode(block.number)));
    if (r == 0) return true;

    tp.joinLottery(address(lot), r);
    return tp.rev() == r && tp.committed();
}



    // reveal not permitted if rev == 0
    function echidna_reveal_requires_commit() public returns (bool) {
    uint256 r = uint256(keccak256(abi.encode(block.timestamp)));

    if (tp.rev() == 0) {
        try tp.revealLottery(address(lot), r) {
            return false;
        } catch {
            return true;
        }
    }
    return true;
}



    // reveal resets rev and committed
  function echidna_reveal_resets_state() public returns (bool) {
    uint256 r = uint256(keccak256(abi.encode(blockhash(block.number - 1))));
    if (r == 0) return true;

    tp.joinLottery(address(lot), r);
    lot.revealTime();

    try tp.revealLottery(address(lot), r) {
        return tp.rev() == 0 && !tp.committed();
    } catch {
        return true;
    }
}


function echidna_only_owner_can_commit() public returns (bool) {
    Attacker attacker = new Attacker(address(tp), address(lot));

    bool success = attacker.tryCommit();

    // the attack should not work
    return !success;
}






    // end lottery set the allowance to 9000
   function echidna_endLottery_sets_9000() public returns (bool) {
    uint256 r = uint256(keccak256(abi.encode(block.timestamp, address(this))));
    if (r == 0) {
        return true;
    }

    tp.joinLottery(address(lot), r);

    try tp.revealLottery(address(lot), r) {
        try lot.endLottery() {
            return tp.getTaxAllowance() == 9000;
        } catch {
            return true;
        }
    } catch {
        return true;
    }
}

    
    
    // a participant cannot appear more than once among potential winners
function echidna_unique_participant_in_lottery() public returns (bool) {
    uint256 r1 = uint256(keccak256("r1"));
    uint256 r2 = uint256(keccak256("r2"));

    tp.joinLottery(address(lot), r1);

    try tp.joinLottery(address(lot), r2) {
        return false; // doppio commit NON ammesso
    } catch {
        return true;
    }
}






// participants with age >= 65 must be rejected
function echidna_reject_participants_over_65() public returns (bool) {
    uint256 r = uint256(keccak256(abi.encode(block.timestamp, address(this), "r")));
    uint256 age = 65 + (uint256(keccak256(abi.encode(block.number))) % 50); // age >= 65

    if (r == 0) {
        return true;
    }

    // set taxpayer age to invalid value
    tp.setAge(age);

    try tp.joinLottery(address(lot), r) {
        return false; // incorrectly accepted
    } catch {
        return true;  // correctly rejected
    }
}



// spousal allowance sum is allowed to change if one spouse wins the lottery
function echidna_spousal_allowance_sum_constant_unless_win() public returns (bool) {
    uint256 r = uint256(keccak256(abi.encode(block.timestamp, address(this), "r")));

    if (r == 0) {
        return true;
    }

    uint256 initialSum = tp.getTaxAllowance();
    try tp.getSpouseTaxAllowance() returns (uint spouseTA) {
        initialSum += spouseTA;
    } catch {
        initialSum += 0;
    }

    tp.joinLottery(address(lot), r);

    lot.revealTime();

    try tp.revealLottery(address(lot), r) {
        try lot.endLottery() {
            uint256 finalSum = tp.getTaxAllowance();
            try tp.getSpouseTaxAllowance() returns (uint spouseTA2) {
                finalSum += spouseTA2;
            } catch {
                finalSum += 0;
            }

            if (tp.getTaxAllowance() != 9000) {
                return finalSum == initialSum;
            }

            return true;
        } catch {
            return true;
        }
    } catch {
        return true;
    }
}


}


// tmp attacker contract
contract Attacker {
    Taxpayer public tp;
    address public lot;
    uint256 private r;

    constructor(address _tp, address _lot) {
        tp = Taxpayer(_tp);
        lot = _lot;
	r = uint256(keccak256(abi.encode(block.timestamp, address(this))));
    }

    function tryCommit() public returns (bool) {
       try tp.joinLottery(lot, r) {
            return true;
        } catch {
            return false;
        }
    }
}

