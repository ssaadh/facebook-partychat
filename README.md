### Pulling in [new] Facebook Messages ###

The code for retrieving new FB messages is written with a few assumptions:
  (1) Script is being run frequently enough so as to only need to retrieve last 25 messages at most.
  (2) More than 25 new messages won't pile up at the pace the script is being run
For myself, I'm planning on running it every minute, so the hope is more than 25 new messages don't come in within the 60 seconds the script was last run.
Fixing this isn't difficult. FB Api allows easy pagination. It just isn't needed right now.