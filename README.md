# FPGA/Verilog RTL 설계 경험서

실제 Unified NTT 가속기가 100 MHz baseline에서 150 MHz 구현으로 발전한 과정을
중심으로, FPGA RTL의 area와 timing을 함께 설명하는 경험서입니다.

특히 실패한 timing run도 설계 기록으로 남겼습니다. 23-bit subtraction과
conditional correction이 한 cycle에 이어진 경로, ML-DSA product 결합 뒤의
12-CARRY4 경로, Montgomery 다중 operand addition, NTRU+ 상수곱의 pipeline
misalignment를 실제 수치와 함께 설명합니다.

기존 판의 반복적인 `개념 → 쉬운 예 → 주의할 예 → 좋은 예 → area → timing`
구성을 정리하고, 다음과 같은 실제 RTL 사례를 `관찰 → 원인 → 구조 변경 → 검증
계약 → 측정 결과` 순서로 다시 구성했습니다.

- DUMP 주소에서 BRAM까지 이어진 8-LUT, 9.077 ns critical path
- DUMP 경로 수정 뒤 드러난 LOAD의 8-LUT, fanout-95 routing 병목
- LOAD/DUMP가 공유하는 registered physical-memory command
- pipeline valid reduction tree를 대체한 occupancy counter
- 2048×23에서 576×23으로 줄인 compact coefficient bank
- scheme별 twiddle ROM을 통합한 packed 2048×32 dual-read ROM
- ML-DSA와 R16 Montgomery multiplication이 공유하는 2-DSP, 6-stage multiplier
- 실제 단일 합성으로 확인한 add/sub/MUX/comparator/shift의 LUT와 CARRY4 비용
- 최초/최종 standalone의 자원별 area--time product 비교
- writeback physical tag와 불필요한 lane-valid/capture register 제거
- AXI backpressure를 처리하는 finite-FIFO credit reservation
- standalone RTL과 두 complete PS–PL system의 area/timing 범위 분리

## 문서

- [경험서 PDF](<FPGA Verilog RTL 설계 경험서/fpga_verilog_rtl_experience_guide.pdf>)
- [메인 TeX](<FPGA Verilog RTL 설계 경험서/fpga_verilog_rtl_experience_guide.tex>)
- [장별 TeX source](<FPGA Verilog RTL 설계 경험서/chapters>)
- [Unified NTT 사례 요약](UNIFIED_NTT_CASE_STUDY.md)

## 목차

1. RTL을 회로로 읽는 기준
2. 측정 범위와 보고서 읽기
3. 사례 설계의 계층과 발전 과정
4. Timing closure 실제 사례
5. 150 MHz에 연산을 담기까지
6. Area와 inference 실제 사례
7. Verilog 연산자의 실제 자원 비용
8. 공유 산술기와 pipeline 설계
9. Scheduler, memory mapping, interface
10. 최적화를 깨지 않게 검증하는 방법
11. 반복 가능한 최적화 workflow
12. 측정 결과와 설계 결론

## PDF 빌드

필요 도구: `latexmk`, `pdflatex`, `kotex`, `tikz`, `tcolorbox`, `listings`.

```sh
make pdf
```

직접 실행하려면:

```sh
cd "FPGA Verilog RTL 설계 경험서"
latexmk -pdf -interaction=nonstopmode -halt-on-error fpga_verilog_rtl_experience_guide.tex
```

생성된 PDF는 TeX source와 같은 디렉터리에 저장됩니다.

## 사례 RTL과 regression

경험서는 companion project의 세 RTL snapshot을 비교합니다.

- `old/rtl_verilog`: 최초 100 MHz RTL
- `rtl_verilog_200mhz`: 200 MHz 목표 timing 실험판
- `rtl_verilog_mc`: 최종 MC V5 RTL

Companion AXI4-Stream project에서 최종 regression은 다음 한 줄로 실행합니다.

```sh
./tool_sim/run_all.sh
```

보존된 100 MHz baseline regression은 다음과 같습니다.

```sh
./old/tool_sim/run_all.sh
```

## 대표 측정 결과

최종 세 범위는 Vivado 2020.2, `xc7z020clg484-1`, 6.666 ns constraint의
post-route 결과입니다.

| Scope | LUT | FF | BRAM tile | DSP48E1 | WNS |
|---|---:|---:|---:|---:|---:|
| Complete AXI4-Stream + DMA + Zynq | 9,014 | 8,764 | 9.0 | 4 | +0.075 ns |
| Complete packed AXI BRAM Controller + Zynq | 8,908 | 6,825 | 6.0 | 4 | +0.006 ns |
| Standalone `MDL` RTL | 4,736 | 2,792 | 6.0 | 4 | +0.089 ns |

Stream system의 추가 3 BRAM-tile equivalents는 AXI DMA의 MM2S/S2MM payload
FIFO에 속합니다. NTT arithmetic 또는 coefficient/twiddle storage 증가로
해석하지 않습니다.

100 MHz 최초 standalone과 150 MHz 최종 standalone의 역사적 비교에서
LUT--time product는 radix-2 계열 40.6\%, NTRU+ 계열 46.9--48.7\%
감소했습니다. LUT, FF, BRAM은 서로 다른 FPGA 자원이므로 하나의 임의 면적값으로
합치지 않고 자원별 ATP를 따로 보고합니다.

## Author

JaeSeok Lee, Kookmin University
