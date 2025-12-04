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



    // commit: rev andd commited are saved
    function echidna_commit_sets_rev_and_flags(uint256 r) public returns (bool) {
        if(r==0) {
            return true;
        }

        tp.joinLottery(address(lot), r);
        // verify the internal state
        return tp.rev() == r && tp.committed() == true;

    }


    // reveal not permitted if rev == 0
    function echidna_reveal_requires_commit(uint256 r) public returns (bool) {
        if(tp.rev() == 0) {
            try tp.revealLottery(address(lot), r) {
                return false;       // didn't have to exit
            } catch {
                return true;
            }
        }

        return true;        // not applicable
    }


    // reveal resets rev and committed
    function echidna_reveal_resets_state(uint256 r) public returns (bool) {
        if(r == 0) {
            return true;
        }

        tp.joinLottery(address(lot), r);

        // simulate the flow of time to enter in thhe reveal phase
        lot.revealTime();       // to avoid warnings

        try tp.revealLottery(address(lot), r) {
            return tp.rev() == 0 && tp.committed() == false;
        } catch {
            return true;        // if fails is due to the time is ok
        }
    }


    // only owner can commit or reveal
    function echidna_only_owner_can_commit(address attacker, uint256 r) public returns (bool) {
        if(attacker == owner) {
            return true;
        }

        try Taxpayer(address(tp)).joinLottery(address(lot), r) {
            return false;
        } catch {
            return true;        // correctly blocked
        }
    }

    // end lottery set the allowance to 9000
    function echidna_endLottery_sets_9000(uint256 r) public returns (bool) {
        if(r==0) {
            return true;
        }

        tp.joinLottery(address(lot), r);

        // reveal phase
        try tp.revealLottery(address(lot), r) {
            // force to the end of the lot
            try lot.endLottery() {
                uint ta = tp.getTaxAllowance();

                return ta == 9000;
            } catch {
                return true;
            }
        } catch {
            return true;
        }
    }



}