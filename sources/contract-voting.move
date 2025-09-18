module MyModule::PrivateVoting {
    use aptos_framework::signer;
    use std::vector;
    use aptos_framework::timestamp;

    /// Error codes
    const E_POLL_NOT_EXISTS: u64 = 1;
    const E_POLL_ENDED: u64 = 2;
    const E_ALREADY_VOTED: u64 = 3;

    /// Struct representing a voting poll
    struct Poll has store, key {
        title: vector<u8>,
        yes_votes: u64,
        no_votes: u64,
        end_time: u64,
        voters: vector<address>,
    }

    /// Function to create a new poll with a title and duration
    public fun create_poll(
        creator: &signer, 
        title: vector<u8>, 
        duration_hours: u64
    ) {
        let end_time = timestamp::now_seconds() + (duration_hours * 3600);
        
        let poll = Poll {
            title,
            yes_votes: 0,
            no_votes: 0,
            end_time,
            voters: vector::empty<address>(),
        };
        
        move_to(creator, poll);
    }

    /// Function for users to cast their vote anonymously
    public fun cast_vote(
        voter: &signer, 
        poll_owner: address, 
        vote: bool
    ) acquires Poll {
        assert!(exists<Poll>(poll_owner), E_POLL_NOT_EXISTS);
        
        let poll = borrow_global_mut<Poll>(poll_owner);
        let voter_addr = signer::address_of(voter);
        
        // Check if poll is still active
        assert!(timestamp::now_seconds() < poll.end_time, E_POLL_ENDED);
        
        // Check if user already voted
        assert!(!vector::contains(&poll.voters, &voter_addr), E_ALREADY_VOTED);
        
        // Record the vote
        if (vote) {
            poll.yes_votes = poll.yes_votes + 1;
        } else {
            poll.no_votes = poll.no_votes + 1;
        };
        
        // Add voter to prevent double voting
        vector::push_back(&mut poll.voters, voter_addr);
    }
}