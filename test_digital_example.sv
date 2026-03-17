module test_digital_example;
    logic [3:0] test_vector [7:0];
    logic a_test, b_test, c_test, out;
    logic tb_out;

    digital_example de_inst(
        .a(a_test), // Connect the input a of digital_example to a_test
        .b(b_test),
        .c(c_test),
        .out(out)   // Can be the same name
    );

    initial begin
        // This is a comment (because it starts with //)
        // Array syntax is '{ elem1, elem2, elem3 }
        test_vector = '{
            4'b0001,
            4'b0011,
            4'b0101,
            4'b0111,
            4'b1001,
            4'b1011,
            4'b1101,
            4'b1111
        };

        for (int i = 0; i < 8; i++) begin
            {a_test, b_test, c_test, tb_out} = test_vector[i];
            #1; // wait one step on the time scale
            assert (out == tb_out);
        end
        $display("All tests passed!");
        $finish;
    end
endmodule
