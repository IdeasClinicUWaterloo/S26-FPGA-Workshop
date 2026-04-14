module digital_example(
    input a,
    input b,
    input c,
    output out
);
    logic gate_1, gate_2, gate_3;
  
    assign gate_1 = a & b;
    assign gate_2 = ~c;
    assign gate_3 = gate_1 ~| gate_2;
    assign out = gate_3 ^ gate_2;

endmodule
