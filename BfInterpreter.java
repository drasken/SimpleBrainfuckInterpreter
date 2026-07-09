import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import java.util.HashMap;
import java.util.LinkedList;
import java.io.IOException;
import java.nio.file.NoSuchFileException;


/**
   This class implement a simple Brainfuck interpreter.
*/
public class BfInterpreter{

    // All fields to encapsulate the interpreter state
    private int[] tape;  // represented as an array of bytes
    private static final int TAPE_LENGTH = 30000;  // standard tape length per the original spec
    private char[] sourceCode;
    private int pc = 0;  // program counter, count instructions
    private int ac = 0;  // array pointer, indexing on tape
    private Map<Integer, Integer> jumpTable;  // used to save indexes of code's brackets


    public BfInterpreter(String filePath) {
	this.tape = new int[TAPE_LENGTH];
	this.sourceCode = readSourceCode(filePath);
	this.jumpTable = makeJumpTable(this.sourceCode);
    }


    /**
       Method used to read the BF source code to execute.
    */
    private char[] readSourceCode(String filePath) {
	String content;

	try {
	    content = Files.readString(Path.of(filePath));
	} catch (NoSuchFileException e) {
	    throw new RuntimeException("Source file not found: " + filePath, e);
	} catch (IOException e) {
	    throw new RuntimeException("Could not read source file: " + filePath, e);
	}

	return content.toCharArray();
    }



    /**
       Method to pre-parse the source code and make a "jump table".
       Each pair of nested bracket is saved as pair of corresponding indexes:
       to each opening [ of pos x and the corresponding ] of pos y
       a pair x: y is saved and vice versas
    */
    private Map<Integer, Integer> makeJumpTable(char[] sourceCode) {

	LinkedList<Integer> myStack = new LinkedList<>();  // Used as a temporary "stack"
	Map<Integer, Integer> res = new HashMap<>();

	for (int pos = 0; pos < sourceCode.length; pos++) {
	    char c = sourceCode[pos];
	    if (c == '[') {
		myStack.addLast(pos);
	    } else if (c == ']') {
		if (myStack.isEmpty()) {
		    throw new IllegalArgumentException("Unmatched ']' at position " + pos);
		}
		int openPos = myStack.removeLast();
		res.put(openPos, pos);
		res.put(pos, openPos);
	    }
	}

	// Safeguard, check if stack is empty
	if (!myStack.isEmpty()) {
	    throw new IllegalArgumentException("Unmatched '[' at position " + myStack.getLast());
	}
	return res;
    }


    /**
       Core function used to implement the execution logic for all the 8 BF commands
    */
    private void runInterpreter() {
	// Run the code until all instructions are executed
	while (this.pc < this.sourceCode.length) {
	    char instruction = this.sourceCode[this.pc];

	    switch (instruction) {
		// inc/dec current cell, both operations are mod 256
	    case '+':
		this.tape[this.ac] = (this.tape[this.ac] + 1) % 256;
		break;
	    case '-':
		this.tape[this.ac] = (this.tape[this.ac] + 255) % 256;
		break;
		// movement instructions
	    case '>':
		if (this.ac < TAPE_LENGTH - 1) {
		    this.ac++;
		} else {
		    throw new RuntimeException("Pointer Overflow");
		}
		break;
	    case '<':
		if (this.ac > 0) {
		    this.ac--;
		} else {
		    throw new RuntimeException("Pointer Underflow");
		}
		break;
		// print/read instructions
	    case '.':
		System.out.print((char) this.tape[this.ac]);
		System.out.flush();  // force the command execution from buffer to terminal immediately
		break;
	    case ',':
		int input;
		try {
		    input = System.in.read();
		} catch (IOException e) {
		    throw new RuntimeException("Error reading input", e);
		}
		this.tape[this.ac] = (input == -1) ? 0 : input;
		break;
		// jump instructions
	    case '[':
		if (this.tape[this.ac] == 0) {
		    this.pc = this.jumpTable.get(this.pc);
		}
		break;
	    case ']':
		if (this.tape[this.ac] != 0) {
		    this.pc = this.jumpTable.get(this.pc);
		}
		break;
		// ignore every other characters
	    default:
		break;
	    }

	    this.pc++;  // advance to next instruction
	}
    }


    /**
       Main function that work as an entry point for using this interpreter.
       Pass the source code file as argument, else print a minimal help string
     */
    public static void main (String[] args) {
	// Only the source code file is expected
	if (args.length != 1) {
	    System.out.println("Usage: java BfInterpreter <file.bf>");
	    return;
	}
	
	BfInterpreter interpreter = new BfInterpreter(args[0]);
	interpreter.runInterpreter();
    }
}
