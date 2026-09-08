# FPGA/Verilog RTL 설계 경험서

Verilog RTL을 읽고 어떤 FPGA 회로가 생기는지, 면적이 얼마나 들지, 한 cycle의
timing이 가능한지를 예측하는 설계 경험서입니다. LUT·FF·Slice·CARRY4·DSP48E1·
BRAM·LUTRAM·SRL의 구조에서 시작해 일반적인 RTL 연산과 coding pattern을 실제
회로로 번역합니다.

Unified NTT 가속기는 이 설명의 대상 자체가 아니라, 설계 직관을 검증하는 실제
사례로 사용합니다. 동일조건 operator synthesis와 100/150/200 MHz post-route
경험을 통해 구조 근사와 실제 LUT·FF·CARRY4·DSP·BRAM 및 ns 결과를 연결합니다.

## 이 저장소가 보여 주는 설계 역량

- LUT6의 입력 수와 1-bit 출력 관점에서 bus logic의 LUT 수를 예측하는 법
- FF 수와 slice packing을 구분하고 control set의 영향을 판단하는 법
- `assign`, clocked `always`, `if/case`, loop가 조합회로·register·MUX·병렬
  hardware가 되는 과정
- add/subtract/comparator/correction/MUX/shift/multiply의 실제 primitive mapping
- bit width, 병렬도, pipeline metadata와 memory port에서 면적을 손으로 추정하는 법
- carry depth, MUX 위치, fanout, logic/route delay에서 timing을 판단하는 법
- BRAM/LUTRAM/SRL/DSP inference가 되는 코드와 깨지는 코드
- 합성 근사치를 post-synthesis utilization과 post-route timing으로 검증하는 방법

실전부에서는 다음 경험을 위의 일반 원칙에 연결합니다.

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

### FPGA 자원과 RTL 합성의 기본기

1. RTL을 회로로 읽는 기준
2. LUT, FF, Slice와 전용 자원의 기본기
3. Verilog 구문을 실제 회로로 번역하는 법
4. Verilog 연산자의 실제 자원 비용
5. BRAM, LUTRAM, SRL과 DSP inference

### 면적과 Timing을 예측하는 설계 직관

6. RTL을 보고 면적을 예측하는 직관
7. 연산과 배선에서 timing을 예측하는 직관
8. 자주 쓰는 RTL 구조의 Area–Timing Trade-off
9. 측정 범위와 보고서 읽기

### Unified NTT에서 검증한 실제 설계 경험

10. 아키텍처를 발전시키는 구조적 판단
11. Memory 경계의 Timing Closure
12. 한 Cycle의 연산량과 Pipeline 배치
13. Memory와 Metadata의 Area 최적화
14. Modular Arithmetic의 자원 공유와 Pipeline
15. Scheduler와 Interface의 성능 및 면적

### 검증, 반복 workflow와 측정 결과

16. 최적화를 깨지 않게 검증하는 방법
17. 반복 가능한 최적화 workflow
18. 측정으로 설계 판단을 검증하는 법

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
