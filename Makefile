BOOK_DIR := FPGA Verilog RTL 설계 경험서
BOOK_TEX := fpga_verilog_rtl_experience_guide.tex

.PHONY: pdf clean

pdf:
	cd "$(BOOK_DIR)" && latexmk -pdf -interaction=nonstopmode -halt-on-error "$(BOOK_TEX)"

clean:
	cd "$(BOOK_DIR)" && latexmk -c "$(BOOK_TEX)"
