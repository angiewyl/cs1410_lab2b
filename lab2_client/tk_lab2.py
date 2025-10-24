###########
# IMPORTS #
###########
# Default libs
import string
import sys
import argparse
import struct

# OK and CS1410 libs
sys.path.insert(0,"../../lib")
import cs1410_lib.utils as cs1410
ok = cs1410.import_oklib(verbose=True)
import cs1410_lib.xem as xem

# TK (GUI) libs
from tkinter import *
from tkinter import ttk

########
# MAIN #
########
def main():
    #Declare and init device
    dev = xem.Device(True)
    result = dev.Initialize()
    dev.setupClock() 

    #Deploy bitstream to FPGA
    bitfile = "alu_top.bit"  #TODO: Change bitstream location and file if needed
    if (dev.downloadFile(bitfile) == False):
        exit(1)

    #Tkinter GUI
    # Create the main window and pass it to the ToggleBoxApp class
    root = Tk()
    app = ToggleBoxApp(root, dev)
    root.mainloop()

    exit(0)

#############
# FUNC DEFS #
#############
def decimal_to_twos_complement(decimal_value):
    # Pack the decimal value as a 32-bit signed integer
    #packed_value = struct.pack('!i', decimal_value)
    packed_value = struct.pack('!I', decimal_value)
    
    # Unpack the packed value as a 32-bit signed integer and get the binary representation
    binary_str = ''.join(format(byte, '08b') for byte in packed_value)

    return binary_str

def send_inputs(dev, in1, in2, in3):
    print(decimal_to_twos_complement(in1))
    in1 = int(decimal_to_twos_complement(in1),2)
    in2 = int(decimal_to_twos_complement(in2),2)

    print(in1)
    print(in2)

    dev.setWire(0x00, in1, 0xffffffff) 
    dev.setWire(0x01, in2, 0xffffffff)
    dev.setWire(0x02, in3, 0xffffffff) 


def read_output(dev):
	
    out = dev.getWire(0x20, 0xffffffff) 
    print(f"out: {out}")
    return out

def read_flags(dev):

    flags = dev.getWire(0x21, 0xffffffff)
    print(f"flags: {flags}")
    return flags


###########
# TTK GUI #
###########
class ToggleBoxApp:
    def __init__(self, root, dev):
        self.root = root
        self.dev = dev
        self.root.title("Toggle Boxes")

        # Inputs 1 and 2 as Entry widgets
        self.entry1 = ttk.Entry(root, font=("Arial", 14))
        self.entry1.insert(0, "0")  # Default value
        self.entry1.pack(pady=10)

        self.entry2 = ttk.Entry(root, font=("Arial", 14))
        self.entry2.insert(0, "0")  # Default value
        self.entry2.pack(pady=10)

        # Buttons for Input 3
        button_frame = ttk.Frame(root)
        button_frame.pack()

        self.input3 = IntVar(value=0)  # Variable to store the selected input 3 value

        # Define buttons and associate them with values
        buttons = {
            "AND (000)": 0,
            "ADD (001)": 1,
            "SUB (010)": 2,
            "SLT (011)": 3,
            "SRL (100)": 4,
            "SRA (101)": 5,
            "SLL (110)": 6,
        }

        for text, value in buttons.items():
            button = Radiobutton(button_frame, text=text, variable=self.input3, value=value, font=("Arial", 14))
            button.pack(side=LEFT, padx=10)

        # Output label setup
        self.output_label = ttk.Label(root, text="Output: 0", font=("Arial", 14), relief="raised", width=15)
        self.output_label.pack(pady=10)

        # Flag label setup
        self.flagz_label = ttk.Label(root, text="Zero: 0", font=("Arial", 14), relief="raised", width=15)
        self.flagz_label.pack(pady=10)

        self.flage_label = ttk.Label(root, text="Equal: 0", font=("Arial", 14), relief="raised", width=15)
        self.flage_label.pack(pady=10)

        self.flago_label = ttk.Label(root, text="Overflow: 0", font=("Arial", 14), relief="raised", width=15)
        self.flago_label.pack(pady=10)

        # Button to update output
        update_button = Button(root, text="Update Outputs", font=("Arial", 14), command=self.update_output)
        update_button.pack(pady=10)

    def update_output(self):
        # Get values from Entry widgets and input 3
        in1 = int(self.entry1.get(),16)
        in2 = int(self.entry2.get(),16)
        in3 = self.input3.get()
        if (in1 > (2**32)-1):
            self.output_label.config(text=f"in1 invalid value")
        elif (in2 > (2**32)-1):
            self.output_label.config(text=f"in2 invalid value")
        else:
            send_inputs(self.dev, in1, in2, in3)
            result = read_output(self.dev)
            flags = read_flags(self.dev)
            # Interpret raw_result as a signed integer using two's complement
            #result = int.from_bytes(raw_result.to_bytes(4, byteorder='big', signed=True), byteorder='big', signed=True)
            self.output_label.config(text=f"Output: {hex(result).lstrip("0x").zfill(8)}")
            self.flago_label.config(text=f"Overflow: {bin((flags >> 2) & 1).lstrip("0b").zfill(1)}")
            self.flage_label.config(text=f"Equal: {bin((flags >> 1) & 1).lstrip("0b").zfill(1)}")
            self.flagz_label.config(text=f"Zero: {bin(flags & 1).lstrip("0b").zfill(1)}")

if __name__ == '__main__':
    main()
