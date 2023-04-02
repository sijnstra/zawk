
# Decode the next instruction into the following global variables:
# op_pc:        Integer  Starting address of this instruction in memory
# op_type:      String   ("0OP", "1OP", "2OP", or "VAR")
# op_code:      Integer opcode
# A0,A1,A2,A3:  Integer operands (-1 means unpopulated)

function op_decode(    b, t) {
    op_pc = cpu_pc
    b = fetch_u8()
    
    # Initial operand values 
    A0 = A1 = A2 = A3 = -1

    if(b == 190 && hdr_version == 5) {
        # Extended instruction (v5)
    } else if(!test_bit(b, 7)) {
        # Long instruction (2OP)
        op_type = "2OP"
        op_code = b % 32
        A0 = op_decode_arg(test_bit(b, 6) + 1)
        A1 = op_decode_arg(test_bit(b, 5) + 1)
    } else if(test_bit(b, 6)) {
        # Variable instruction (2OP or VAR arity)
        op_type = test_bit(b, 5) ? "VAR" : "2OP"
        op_code = b % 32
        b = fetch_u8()
        if((t = int(b / 64)) != 3) {
            A0 = op_decode_arg(t)
            if((t = int(b / 16) % 4) != 3) {
                A1 = op_decode_arg(t)
                if((t = int(b / 4) % 4) != 3) {
                    A2 = op_decode_arg(t)
                    if((t = int(b % 4)) != 3) {
                        A3 = op_decode_arg(t)
                    }
                }
            }
        }
    } else {
        # Short instruction (0OP or 1OP)
        op_code = b % 16 
        A0 = op_decode_arg((b / 16) % 4)
        op_type = A0 < 0 ? "0OP" : "1OP"
    }
}

function op_decode_arg(type) {
    if(type == 0) {
        return fetch_u16();
    } else if(type == 1) {
        return fetch_u8();
    } else if(type == 2) {
        return var_get(fetch_u8());
    } else {
        return 0;
    }
}

function op_dispatch() {
    op_print()
    if(op_type == "0OP") {
        op_dispatch_0op()
    } else if(op_type == "1OP") {
        op_dispatch_1op() 
    } else if(op_type == "2OP") {
        op_dispatch_2op()
    } else if(op_type == "VAR") {
        op_dispatch_var()
    }
}

function op_unknown() {
    printf("Unknown opcode: ")
    op_print()
    cpu_break = 1
}

function op_print() {
    printf("%04X: %s %d (", op_pc, op_type, op_code)
    if(A0 >= 0) {
        printf("%d", A0)
        if(A1 >= 0) {
            printf(" %d", A1)
            if(A2 >= 0) {
                printf(" %d", A2)
                if(A3 >= 0) {
                    printf(" %d", A3)
                }
            }
        }
    }
    printf(")\n")
}

function op_dispatch_0op() {
    if(op == 0) {
        # true
        cpu_ret(1)
    } else if(op == 1) {
        # false
        cpu_ret(0)
    } else if(op == 2) {
        # print
        printf("TODO: print\n")
    } else if(op == 3) {
        # print-ret
        printf("TODO: print-ret\n")
    } else if(op == 8) {
        # ret-popped
        cpu_ret(stack_pop())
    } else if(op == 9) {
        # pop
        stack_pop()
    } else if(op == 10) {
        # quit
        cpu_break = 1
    } else if(op == 11) {
        # new-line
        printf("\n")
    } else if(op == 13) {
        # verify
        cpu_branch(1)
    } else {
        op_unknown()
    }
}

function op_dispatch_1op(   r, t) {
    if(op_code == 0) {
        # jz
    } else if(op_code == 1) {
        # get_sibling
        r = fetch_u8()
        t = obj_sibling(A0)
        cpu_branch(t >= 0)
        var_set(r, t)
    } else if(op_code == 2) {
        # get_child
        r = fetch_u8()
        t = obj_child(A0)
        cpu_branch(t >= 0)
        var_set(r, t)
    } else if(op_code == 3) {
        # get_parent
        r = fetch_u8()
        t = obj_parent(A0)
        var_set(r, t)
    } else if(op_code == 4) {
        # get_prop_len
        r = fetch_u8()
        t = obj_prop_len(A0)
        var_set(r, t)
    } else if(op_code == 5) {
        # inc
        var_set(A0, var_get_signed(A0) + 1)
    } else if(op_code == 6) {
        # dec
        var_set(A0, var_get_signed(A0) - 1)
    } else if(op_code == 7) {
        # print_addr
        printf("TODO: print_addr\n")
    } else if(op_code == 9) {
        # remove_obj
        obj_remove(A0)
    } else if(op_code == 10) {
        # print_obj
        printf("TODO: print_obj\n")
    } else if(op_code == 11) {
        # ret
        cpu_ret(A0)
    } else if(op_code == 12) {
        # jump
        cpu_pc += (to_s16(A0) - 2)
    } else if(op_code == 13) {
        # print_paddr
        printf("TODO: print_paddr\n")
    } else if(op_code == 14) {
        # load
        r = fetch_u8()
        if(A0 == 0) {
            stack_push(stack_top()) # 6.3.4
        }
        t = var_get(A0)
        var_set(r, t)
    } else if(op_code == 15) {
        r = fetch_u8()
        printf("TODO: not\n")
        var_set(r, A0)
    } else {
        op_unknown()
    }
}

function op_dispatch_2op(   t) {
    if(op_code == 1) {
        # je
        cpu_branch(A0 == A1 || A0 == A2 || A0 == A3)
    } else if(op_code == 2) {
        # jl
        cpu_branch(to_s16(A0) < to_s16(A1))
    } else if(op_code == 3) {
        # jg
        cpu_branch(to_s16(A0) > to_s16(A1))
    } else if(op_code == 4) {
        # dec-chk
        t = var_get_signed(A0) - 1
        var_set(A0, t)
        cpu_branch(val < to_s16(A1))
    } else if(op_code == 5) {
        # inc-chk
        t = var_get_signed(A0) + 1
        var_set(A0, t)
        cpu_branch(val < to_s16(A1))
    } else if(op_code == 6) {
        # jin
        cpu_branch(obj_parent(arg[0]) == arg[1])
    } else if(op_code == 7) {
        # test
        printf("TODO: test\n")
    } else if(op_code == 8) {
        # or
        var_set(fetch_u8(), logand(A0, A1))
    } else if(op_code == 9) {
        # and
        var_set(fetch_u8(), logior(A0, A1))
    } else if(op_code == 10) {
        # test_attr
        cpu_branch(obj_attr(A0, A1))
    } else if(op_code == 11) {
        # set_attr
        obj_set_attr(A0, A1, 1)
    } else if(op_code == 12) {
        # clear_attr
        obj_clear_attr(A0, A1, 0)
    } else if(op_code == 13) {
        # store
        if(arg[0] == 0) {
            stack_pop() # 6.3.4
        }
        var_set(A0, A1)
    } else if(op_code == 14) {
        # insert_obj
        obj_insert(A0, A1)
    } else if(op_code == 15) {
        # loadw
        r = fetch_u8()
        t = mem_read_u16(A0 + 2 * A1)
        var_set(r, t)
    } else if(op_code == 16) {
        # loadb
        r = fetch_u8()
        t = mem_read_u8(A0 + A1)
        var_set(r, t)
    } else if(op_code == 17) {
        # get_prop
        r = fetch_u8()
        t = obj_prop(A0, A1)
        var_set(r, t)
    } else if(op_code == 18) {
        # get_prop_addr
        r = fetch_u8()
        t = obj_prop_addr(A0, A1)
        var_set(r, t)
    } else if(op_code == 19) {
        # get_next_prop
        r = fetch_u8()
        if(A1 == 0) {
            t = obj_first_prop(A0)
        } else {
            t = obj_next_prop(A0, A1)
        }
        var_set(r, t)
    } else if(op_code == 20) { 
        # add
        var_set(fetch_u8(), A0 + A1)
    } else if(op_code == 21) { 
        # sub
        var_set(fetch_u8(), A0 - A1)
    } else if(op_code == 22) { 
        # mul
        var_set(fetch_u8(), A0 * A1)
    } else if(op_code == 23) { 
        # div
        var_set(fetch_u8(), int(A0 / A1))
    } else if(op_code == 24) { 
        # mod
        var_set(fetch_u8(), int(A0 % A1))
    } else {
        op_unknown()
    }
}

function op_dispatch_var(    t) {
    if(op_code == 0) {
        # call
        op_call()
    } else if(op_code == 1) {
        # storew
        mem_write_u16(A0 + 2 * A1, A2)
    } else if(op_code == 2) {
        # storeb
        mem_write_u8(A0 + A1, A2)
    } else if(op_code == 3) {
        # put_prop
        obj_put_prop(A0, A1, A2)
    } else if(op_code == 4) {
        # read
        printf("TODO: read")
    } else if(op_code == 5) {
        # print_char
        printf("%c", A0)
    } else if(op_code == 6) {
        # print_num
        printf("%d", to_s16(A0))
    } else if(op_code == 7) {
        # random
        printf("TODO: random")
    } else if(op_code == 8) {
        # push
        stack_push(A0)
    } else if(op_code == 9) {
        # pull
        t = stack_pop()
        if(A0 == 0) {
            stack_pop() # 6.3.3
        }
        var_set(A0, t)
    } else {
        op_unknown()
    }
}

function op_call(   ret_var, routine, num_locals, i, local) {
    ret_var = fetch_u8()
    routine = A0
    if(routine == 0) {
        var_set(ret_var, 0)
    } else {
        stack_push(ret_var)
        stack_push(cpu_pc)
        stack_push_frame()
        cpu_pc = routine * 2
        num_locals = fetch_u8()
        for(i = 0; i < num_locals; i++) {
            local = fetch_u16()
            if(i == 1 && A1 >= 0) {
                stack_push(A1)
            } else if(i == 2 && A2 >= 0) {
                stack_push(A2)
            } else if(i == 3 && A3 >= 0) {
                stack_push(A3)
            } else {
                stack_push(local)
            }
        }
    }
}

