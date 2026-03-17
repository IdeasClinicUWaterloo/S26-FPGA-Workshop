# Workshop 1: Intro to FPGAs

Welcome to the Introduction to FPGAs workshop!

* _Who is this workshop for?_ all undergraduate students who want to learn how FPGAs work, and how to make FPGAs work for them.
* _What will you learn?_ What the technology is, the motivations for creating and using the technology, common design practices, and usage examples.
* _How will you learn it?_ You will use interactive code examples below, running on your own laptop, with all dependencies pre-installed.
* _Can I learn more?_ Workshop two is in-person: you'll be able to apply the concepts you learn here to a physical FPGA evaluation board. It is on `PLACEHOLDER_DATE` at `PLACEHOLDER_LOCATION`.

## What is an FPGA?

An FPGA (field-programmable gate array) is a chip you can program to do any task you want by wiring up its internal components in different ways. Think of it as a set amount of blocks, each which may be connected to any other, and which may be reconnected again and again so that the same inputs become different outputs on each reconfiguration.

> A digital circuit is a circuit where the inputs and outputs are booleans (only ones and zeroes). When inputs change, we may make the assumption that the outputs will change immediately after (after a very small time). How the outputs change is determined by the "gates" that the inputs pass through. Each gate is represented by a **symbol** in a **circuit diagram**. Certain gates are **fundamental** in that they are easily converted from the logical representation to a physical form (electrical circuit).

![An example digital circuit, showcasing the most common visual features of gate symbols using symbols for AND, NOT, NOR, and XOR](./images/ex-digital-circuit.svg)

The diagram above shows a digital circuit with a single output, named `out` and three inputs `a`, `b`, and `c`. Let's build up our intuition on what each gate does. Well, its symbol tells us:

|Symbol|Name|What it does|
|---|---|---|
|![buffer-symbol](./images/Buffer_ANSI_Labelled.svg)|Buffer|The output is equal to the input.|
|![and-gate](./images/AND_ANSI_Labelled.svg)|AND|The output is one only if **all inputs are 1**, else it is zero.|
|![or-gate](./images/OR_ANSI_Labelled.svg)|OR|The output is one if **any input is 1**, else it is zero.|
|![inverter](./images/NOT_ANSI_Labelled.svg)|NOT|The output is the opposite of the input. If the input is one, the output is zero; if the input is zero, the output is one.|
|![xor-gate](./images/XOR_ANSI_Labelled.svg)|XOR (exclusive or)|The output is one only if **exactly one input is 1**.|

![The same example digital circuit, now labelled with numbers: AND is symbol number one, NOT is symbol number two, NOR is symbol number three, and XOR is symbol number four.](./images/ex-digital-circuit-labelled.svg)

Tracing our path through this digital circuit: some of the gates are listed above, and therefore we know how their outputs are produced. In fact, one way of giving names to each gate's output is to write the gate name and then the inputs of the gate in brackets. But what does gate three do? Gate three is an OR gate with the same circle in front as gate two, a NOT gate. It outputs the opposite of what an OR gate would output for its inputs. It is called a NOR (Not-OR) gate.


> Now, using the same reasoning approach, what does the below gate do? What is its name?
>
> ![nand-gate](./images/NAND_ANSI_Labelled.svg)

### All Digital Circuits are Tables

How would we reason through the output of this entire digital circuit?
One way is with a table of inputs to outputs, called a _truth table_.
Each unique input combination is listed on the left hand side, and the corresponding output is written on the right hand side. How would this look for the output named `out` of the circuit we have been working with?

![The same labelled example circuit.](./images/ex-digital-circuit-labelled.svg)

Well, if `out = XOR(NOR(AND(a, b), NOT(c)), NOT(c))`, the final truth table is:

|a|b|c|`out`|
|---|---|---|---|
|0|0|0|**1**|
|0|0|1|**1**|
|0|1|0|**1**|
|0|1|1|**1**|
|1|0|0|**1**|
|1|0|1|**1**|
|1|1|0|**1**|
|1|1|1|**0**|

> Exercise: reason out this truth table. How can you check that it is correct?

> Why can all digital circuits be represented using a truth table listing every single possible input combination?

### Tables can Verify Digital Circuits

_Or: the interface versus the implementation_

What if we already know what every output should be for a digital circuit, for every possible combination of input values? An engineer must implement this specification.

For example, what is another circuit which could generate the truth table we saw earlier? Could we use fewer gates? (less cost).

|a|b|c|`out`|
|---|---|---|---|
|0|0|0|**1**|
|0|0|1|**1**|
|0|1|0|**1**|
|0|1|1|**1**|
|1|0|0|**1**|
|1|0|1|**1**|
|1|1|0|**1**|
|1|1|1|**0**|

To start answering these questions, we can first prepare a **test bench**. A test bench is a program which verifies that a digital circuit is correct, given a specification, by providing to it different inputs and checking that the output matches the truth table of what we want. The digital circuit is called a _design under test_ (DUT) while the test bench provides it inputs. A useful digital circuit will have thousands of input bits, so a test bench may not check every possible input combination. Some techniques to reduce the number of needed input combinations include:

1. Checking that common inputs or input sequences (test vectors, vectors in that a vector consists of all of the inputs at the same time) result in the correct output.
2. Checking "edge cases".
3. Checking random input combinations. The test bench will calculate the expected outputs on the fly and compare them to the digital circuit's output.

> A related verification technique is named _formal verification_. In this method, logical assertions on the output of a digital circuit are given along with the description of the circuit (in the same code). The verification tool then tries to find an input vector which is a counterexample to the assertion.

In the next section we will represent the digital circuit we saw earlier with a structured _hardware description language_ (HDL) named Verilog. We will then write a test bench for this Verilog code to make sure it works.




```python

```
