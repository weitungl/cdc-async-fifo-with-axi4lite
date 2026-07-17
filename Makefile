VCS = vcs -sverilog -debug_access+all -timescale=1ns/1ps

all:
	$(VCS) +incdir+tb rtl/*.sv tb/tb_top.sv -R

clean:
	rm -rf csrc simv simv.daidir ucli.key DVEfiles *.fsdb *.vcd *.h