# Unified NTT RTL 최적화 사례 요약

이 문서는 경험서에서 다루는 실제 설계 변화의 빠른 인덱스입니다. 자세한 코드,
수식, 검증 항목은 [경험서 PDF](<FPGA Verilog RTL 설계 경험서/fpga_verilog_rtl_experience_guide.pdf>)의
4–12장을 참고하십시오.

## 150 MHz에 담기 위해 실패한 것

| 관찰 | 왜 한 cycle에 들어가지 않았나 | 최종 판단 |
|---|---|---|
| 초기 150 MHz의 radix-3 subtraction path: 6.677 ns, 11 CARRY4, WNS -0.338 ns | 23-bit raw subtraction, conditional `+q`, mode 선택이 직렬화됨 | C1에서 raw/borrow를 등록하고 원래 alignment 자리인 C2에서 correction |
| 200 MHz 산술 실험의 ML-DSA path: 8.168 ns, 12 CARRY4, WNS -3.171 ns | DSP product 결합 뒤 reduction field 합이 같은 경계에 이어짐 | DSP1 PREG, C3 field sum 재사용, C4 residual, C5/C6 correction으로 역할 분할 |
| Montgomery `u` 생성의 다섯 operand addition | 네 shifted operand와 `T[15:7]` addition이 한 cone에 모임 | C2에는 9-bit correction만 저장하고 다음 DSP-input cycle에서 `T[15:7]`을 더함 |
| NTRU+ 상수곱을 3-stage로 만든 실험 | 상수곱만 한 cycle 늦어져 parallel difference rail과 기능 정렬이 깨짐 | 2-cycle 계약을 유지하고 underflow 보정 효과 `+168`을 table 선택에 흡수 |
| runtime-generic folded ALU와 lazy reduction | ALU 수는 줄지만 wide MUX, mode fanout, alignment FF, output canonicalization이 돌아옴 | DSP처럼 큰 자원만 공유하고 NTRU+ cycle-local add/sub는 12-bit로 유지 |

이 수치들은 서로 다른 개발 snapshot의 실패 원인을 보여 주는 기록입니다. 전체
WNS 차이를 특정 변경 하나의 개선량으로 해석하지 않습니다.

## 1. 출발점

최초 100 MHz RTL은 이미 radix-2 CT/GS, radix-3 NTT/INTT, trinomial
NTT/INTT를 하나의 butterfly datapath에서 지원했습니다. 최적화의 목표는 기능
통합이 아니라 memory address/control path, storage density, arithmetic sharing,
pipeline alignment, scheduler와 interface를 개선하는 것이었습니다.

## 2. Timing 판단의 변화

| 시점 | 최악 경로/결과 | 판단 |
|---|---|---|
| 100 MHz OOC | DUMP address → BRAM, 8 LUT, 9.077 ns, route 81.5%, WNS +0.273 ns | logical mapping과 phase mux를 RAM pin 앞에서 분리 |
| 200 MHz 목표판 | DUMP 수정 뒤 LOAD → BRAM, 8 LUT, fanout 95, 7.913 ns, WNS −3.563 ns | LOAD/DUMP command 전체를 하나의 registered boundary로 재구성 |
| 최종 150 MHz | memory-address path가 최악 경로에서 사라짐 | scheduler와 butterfly arithmetic이 다음 병목 |

핵심 변경은 다음과 같습니다.

- LOAD와 DUMP의 side/row/data를 하나의 `host_*_q` register bank에서 공유
- `{side,row}` physical tag를 result와 함께 pipeline하여 writeback remapping 제거
- `|valid_pipe` reduction tree를 작은 occupancy counter로 대체
- top FSM이 보장하는 phase exclusivity를 이용해 memory path의 중복 `!oBUSY` 제거
- 4-lane host transaction의 고정 A,A,B,B port pattern을 상수 wire로 표현

## 3. Area 판단의 변화

- Coefficient bank: 2048×23 네 개에서 실제 최대 row에 맞춘 576×23 네 개로 축소
- Coefficient storage: 6 BRAM tile → 4 RAMB36
- Twiddle storage: scheme별 ROM 1.5 tile → Falcon까지 포함한 packed dual-read ROM 2 RAMB36
- Accelerator 전체 memory: 7.5 tile → 6 tile

동일 boundary register 조건의 단일 OOC synthesis에서는 23-bit add/sub가 각각
23 LUT와 6 CARRY4, 한-cycle modular subtraction이 46 LUT와 12 CARRY4,
23-bit 2:1/4:1 MUX가 각각 23 LUT로 구현되었습니다. Constant shift는 0 LUT,
variable shift는 64 LUT였으며 23x16 multiply는 DSP48E1 한 개로 흡수됐습니다.
16-cycle×23-bit delay는 reset이 없을 때 SRL16E 23개와 FF 46개, 전체 delay를
reset하면 SRL 없이 FF 368개로 합성됐습니다. 32×8 asynchronous-read memory는
LUTRAM 8개, 576×23 synchronous memory는 RAMB36E1 한 개를 사용했습니다.
재현 자료는 [operator-cost micro-benchmark](examples/operator_cost)에 있습니다.

- Production configuration에서 네 32-bit cycle counter/incrementer 제거
- 고정 lane-valid 조건과 physical tag로 중복 metadata logic 축소

Twiddle memory 자체는 0.5 tile 증가했습니다. 전체 1.5-tile 감소는 coefficient
storage의 2-tile 감소와 함께 계산한 결과입니다.

## 4. Arithmetic sharing

최종 `unifiedMUL`은 6-stage, II=1이며 두 DSP48E1을 사용합니다.

- DSP0: `A × B[15:0]` 공통 low product
- DSP1: ML-DSA high partial product 또는 R16 Montgomery의 `u × q`
- DSP1 ALU/PREG: ML-DSA aligned addition 또는 Montgomery의 `T − uq`
- Final correction: ML-DSA와 narrow-prime path가 하나의 addition stage 공유

`unifiedBUT`에는 `unifiedMUL`이 두 개 있으므로 전체 DSP 사용량은 4개입니다.

## 5. 최종 측정

Vivado 2020.2, `xc7z020clg484-1`, 150 MHz post-route:

| Scope | LUT | FF | BRAM tile | DSP | WNS |
|---|---:|---:|---:|---:|---:|
| AXI4-Stream + DMA + Zynq | 9,014 | 8,764 | 9.0 | 4 | +0.075 ns |
| Packed AXI BRAM Controller + Zynq | 8,908 | 6,825 | 6.0 | 4 | +0.006 ns |
| Standalone `MDL` | 4,736 | 2,792 | 6.0 | 4 | +0.089 ns |

Standalone 100 MHz와 150 MHz 결과는 top/package/constraint가 완전히 같지 않은
historical milestone입니다. 따라서 LUT 10.3%, FF 9.1%, BRAM 20% 감소는 개발
결과의 변화량으로 제시하며, 특정 변경 하나의 독립적인 효과로 주장하지 않습니다.

## 6. 자원별 area–time product

FPGA의 LUT, FF, BRAM과 DSP는 서로 다른 자원이므로 임의의 가중치로 하나의
면적값을 만들지 않았습니다. Standalone 자원 수와 core 실행시간을 이용해
`LUT×time`, `FF×time`, `BRAM-tile×time`을 각각 계산했습니다.

| Configuration | Core time 감소 | LUT×time 감소 | FF×time 감소 | BRAM×time 감소 |
|---|---:|---:|---:|---:|
| ML-KEM-256 | 33.8% | 40.6% | 39.8% | 47.0% |
| ML-DSA-256 | 33.8% | 40.6% | 39.8% | 47.0% |
| HAETAE-256 | 33.8% | 40.6% | 39.8% | 47.0% |
| NTRU+768 | 41.0% | 47.0% | 46.4% | 52.8% |
| NTRU+864 | 42.8% | 48.7% | 48.0% | 54.3% |
| NTRU+1152 | 40.8% | 46.9% | 46.2% | 52.6% |

예를 들어 ML-KEM core time은 557 cycle/100 MHz의 5.570 us에서
553 cycle/150 MHz의 3.687 us로 감소했습니다. LUT×time 개선은
`1-(4736×3.687)/(5278×5.570)=40.6%`입니다. 이 표 역시 최초부터 최종까지의
전체 역사적 변화이며 단일 RTL 수정의 독립 효과가 아닙니다.
