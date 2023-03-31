
function mem_init() {
    # Setup the FS split after every character (this is implementation
    # specific), and the RS to never split. Some implementations will
    # still start a new record when they encounter a nul character.
    FS=""
    RS="$a"
}

function mem_load_chunk( i) {
    for(i = 1; i <= NF; i++) {
        mem[mem_size++] = ord[$i]
    }
    # Some versions of awk will terminate records on nul characters, 
    # so add an extra nul. We may end up with an extra nul at the end of 
    # the file, but this doesn't matter.
    mem[mem_size++] = 0 
}

function mem_dump( i) {
    for(i = 0; i < mem_size; i++) {
        printf("%02X\n", mem[i])
    }
}

function mem_read_u8(addr) {
    return mem[addr]
}

function mem_read_u16(addr) {
    return mem[addr] * 256 + mem[addr+1]
}

BEGIN { mem_init() }
{ mem_load_chunk() }
