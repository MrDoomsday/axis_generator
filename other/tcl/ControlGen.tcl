#offset
set offset_generator 0x10000


#parameter generator
set auto_length 0x0
set auto_channel 0x0
set auto_pause 0x1
set use_limit_transaction 0x0

set fixed_length 0x100
set min_length 0x40
set max_length 0x80

set fixed_channel 0x0
set min_channel 0x0
set max_channel 0x15

set fixed_pause 0x1000
set min_pause 0x0
set max_pause 0x15000

set count_packet 1000000

#procedure
proc write {address value} {
    #remove 0x...
    set address_prefix [string range $address 0 1]
    if {$address_prefix == "0x"} {
        set address [string range $address 2 [expr {[string length $address]-1}]]
        puts "Prefix address in 0x..."
    }

    set value_prefix [string range $value 0 1]
    if {$value_prefix == "0x"} {
        set value [string range $value 2 [expr {[string length $value]-1}]]
        puts "Prefix value in 0x..."
    }

    #align data - добиваем нулями, т.к. в противном случае будут проблемы
    set value_align [string repeat "0" [expr 8-[string length $value]]]
    set value $value_align$value

    create_hw_axi_txn -quiet -force wr_tx [get_hw_axis hw_axi_1] -address $address -data $value -len 1 -size 32 -type write
    run_hw_axi -quiet wr_tx
    puts "Address = $address"
    puts "Data = $value"
}

proc read {address} {
    set address [string range $address 2 [expr {[string length $address]-1}]]
    # create_hw_axi_txn -quiet -force rd_tx [get_hw_axis hw_axi_1] -address $address -len 1 -size 32 -type read
    # run_hw_axi -quiet rd_tx
    # return 0x[get_property DATA [get_hw_axi_txn rd_tx]]
}


proc generator_init {offset_generator min_length max_length fixed_length min_channel max_channel fixed_channel min_pause max_pause fixed_pause count_packet} {
    write [format %x [expr $offset_generator + (0x1 << 2)]] $fixed_length
    write [format %x [expr $offset_generator + (0x2 << 2)]] $min_length
    write [format %x [expr $offset_generator + (0x3 << 2)]] $max_length

    write [format %x [expr $offset_generator + (0x4 << 2)]] $fixed_channel
    write [format %x [expr $offset_generator + (0x5 << 2)]] $min_channel
    write [format %x [expr $offset_generator + (0x6 << 2)]] $max_channel

    write [format %x [expr $offset_generator + (0x7 << 2)]] $fixed_pause
    write [format %x [expr $offset_generator + (0x8 << 2)]] $min_pause
    write [format %x [expr $offset_generator + (0x9 << 2)]] $max_pause

    write [format %x [expr $offset_generator + (0xA << 2)]] $count_packet
    puts "Generator init complete!"
}

proc generator_start {offset_generator auto_length auto_channel auto_pause use_limit_transaction} {
    set control [expr ($use_limit_transaction << 5) | ($auto_pause << 4) | ($auto_channel << 3) | ($auto_length << 2) | (0 << 1) | 0x1]
    write [format %x [expr $offset_generator + (0x0 << 2)]] [format %x $control]
    puts "Generator is start!"
}


proc generator_stop {offset_generator} {
    write [format %x [expr $offset_generator + (0x0 << 2)]] 0x2
    puts "Generator stopped!"
}
#################################################################################################################
############## Set generator!
generator_stop $offset_generator
generator_init $offset_generator $min_length $max_length $fixed_length $min_channel $max_channel $fixed_channel $min_pause $max_pause $fixed_pause $count_packet
generator_start $offset_generator $auto_length $auto_channel $auto_pause $use_limit_transaction

#generator_stop $offset_generator