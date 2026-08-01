---
id: A-2026-08-01-034
session: none
type: info
title: "100 Random Tag Priority Scenarios"
created: 2026-08-01T00:00:00Z
---

> **Arşiv.** Kaynak: `taskr@project-taskr:TAG_PRIORITY_SCENARIOS_100.md` — 2026-08-01'de
> olduğu gibi taşındı, içeriği değiştirilmedi. Project Taskr arşive
> kaldırıldığı için bu belge tarihsel kayıttır; güncel değildir.

# 100 Random Tag Priority Scenarios

Generated from the current Taskr tag-priority algorithm on 2026-05-10. Results are sorted by final output ascending.

## Legend

- `Manual`: user-entered task priority. When present, it always wins.
- `Tags`: selected tag priority definitions. `x` means exact value, `a-b` means range.
- `Rule Path`: the exact rule branch used by the resolver.
- `Explanation`: compact trace of how the result was computed.

## Scenarios

### 87. Output: 9
- Manual: 9
- Tags: 66-70, 54-70
- Rule Path: manual override
- Explanation: manual priority 9 wins over all tag rules

### 4. Output: 14
- Manual: none
- Tags: 14
- Rule Path: exact-only average
- Explanation: average(14) = 14

### 76. Output: 16
- Manual: none
- Tags: 12, 20-68
- Rule Path: mixed exact below range
- Explanation: single range: 20-68; exactAvg 12 < 20; average(12, 20) = 16

### 23. Output: 17
- Manual: none
- Tags: 31-60, 3
- Rule Path: mixed exact below range
- Explanation: single range: 31-60; exactAvg 3 < 31; average(3, 31) = 17

### 66. Output: 20.5
- Manual: none
- Tags: 32, 9
- Rule Path: exact-only average
- Explanation: average(32, 9) = 20.5

### 53. Output: 25.33
- Manual: none
- Tags: 2, 16, 58
- Rule Path: exact-only average
- Explanation: average(2, 16, 58) = 25.33

### 93. Output: 25.33
- Manual: none
- Tags: 23-50, 21, 21, 34
- Rule Path: mixed exact inside range
- Explanation: single range: 23-50; exactAvg 25.33 is inside 23-50, so exactAvg wins

### 77. Output: 26
- Manual: none
- Tags: 15-30, 18-83, 26
- Rule Path: mixed exact inside range
- Explanation: two-range overlap: 18-30; exactAvg 26 is inside 18-30, so exactAvg wins

### 8. Output: 28.13
- Manual: none
- Tags: 72-81, 15, 15-86, 75-97, 3-59
- Rule Path: mixed exact below range
- Explanation: 3+ ranges synthetic range: avg(mins)=41.25, avg(maxes)=80.75; exactAvg 15 < 41.25; average(15, 41.25) = 28.13

### 13. Output: 29
- Manual: 29
- Tags: 73-78
- Rule Path: manual override
- Explanation: manual priority 29 wins over all tag rules

### 50. Output: 29
- Manual: none
- Tags: 6, 33, 6, 30-39, 47-72
- Rule Path: mixed exact + scalar range result
- Explanation: two-range gap midpoint: (39 + 47) / 2 = 43; average(exactAvg=15, scalar=43) = 29

### 11. Output: 30
- Manual: 30
- Tags: 34, 43, 36-39, 67-89, 100
- Rule Path: manual override
- Explanation: manual priority 30 wins over all tag rules

### 42. Output: 30
- Manual: none
- Tags: 30
- Rule Path: exact-only average
- Explanation: average(30) = 30

### 29. Output: 35
- Manual: 35
- Tags: 35-72
- Rule Path: manual override
- Explanation: manual priority 35 wins over all tag rules

### 31. Output: 36.5
- Manual: none
- Tags: 27, 43-69, 52, 11
- Rule Path: mixed exact below range
- Explanation: single range: 43-69; exactAvg 30 < 43; average(30, 43) = 36.5

### 71. Output: 37
- Manual: none
- Tags: 32-35, 40-70, 50, 23
- Rule Path: mixed exact + scalar range result
- Explanation: two-range gap midpoint: (35 + 40) / 2 = 37.5; average(exactAvg=36.5, scalar=37.5) = 37

### 90. Output: 37
- Manual: none
- Tags: 37
- Rule Path: exact-only average
- Explanation: average(37) = 37

### 40. Output: 37.13
- Manual: none
- Tags: 64-98, 28-51, 19-93, 33, 54-74
- Rule Path: mixed exact below range
- Explanation: 3+ ranges synthetic range: avg(mins)=41.25, avg(maxes)=79; exactAvg 33 < 41.25; average(33, 41.25) = 37.13

### 15. Output: 37.5
- Manual: none
- Tags: 17, 46, 18-33, 54-100
- Rule Path: mixed exact + scalar range result
- Explanation: two-range gap midpoint: (33 + 54) / 2 = 43.5; average(exactAvg=31.5, scalar=43.5) = 37.5

### 59. Output: 38
- Manual: 38
- Tags: 62, 56-87
- Rule Path: manual override
- Explanation: manual priority 38 wins over all tag rules

### 80. Output: 38.51
- Manual: none
- Tags: 10-43
- Rule Path: range-only random pick
- Explanation: single range: 10-43; random pick in 10-43 => 38.51

### 86. Output: 39
- Manual: none
- Tags: 39
- Rule Path: exact-only average
- Explanation: average(39) = 39

### 61. Output: 39.5
- Manual: none
- Tags: 43, 58-92, 11-14
- Rule Path: mixed exact + scalar range result
- Explanation: two-range gap midpoint: (14 + 58) / 2 = 36; average(exactAvg=43, scalar=36) = 39.5

### 60. Output: 39.8
- Manual: none
- Tags: 43, 62, 40, 31, 23
- Rule Path: exact-only average
- Explanation: average(43, 62, 40, 31, 23) = 39.8

### 19. Output: 40.5
- Manual: none
- Tags: 19, 62, 17-67
- Rule Path: mixed exact inside range
- Explanation: single range: 17-67; exactAvg 40.5 is inside 17-67, so exactAvg wins

### 97. Output: 42.63
- Manual: none
- Tags: 33-60, 40-92, 55-80, 1-6
- Rule Path: range-only random pick
- Explanation: 3+ ranges synthetic range: avg(mins)=32.25, avg(maxes)=59.5; random pick in 32.25-59.5 => 42.63

### 72. Output: 43
- Manual: none
- Tags: 6-23, 63-82
- Rule Path: range-only scalar result
- Explanation: two-range gap midpoint: (23 + 63) / 2 = 43

### 30. Output: 43.25
- Manual: none
- Tags: 40, 14-17, 76-98
- Rule Path: mixed exact + scalar range result
- Explanation: two-range gap midpoint: (17 + 76) / 2 = 46.5; average(exactAvg=40, scalar=46.5) = 43.25

### 52. Output: 44
- Manual: 44
- Tags: 28, 78-90, 11
- Rule Path: manual override
- Explanation: manual priority 44 wins over all tag rules

### 37. Output: 45
- Manual: none
- Tags: 55, 48, 32
- Rule Path: exact-only average
- Explanation: average(55, 48, 32) = 45

### 100. Output: 46
- Manual: none
- Tags: 11, 49, 62-85
- Rule Path: mixed exact below range
- Explanation: single range: 62-85; exactAvg 30 < 62; average(30, 62) = 46

### 12. Output: 46.5
- Manual: none
- Tags: 54, 39
- Rule Path: exact-only average
- Explanation: average(54, 39) = 46.5

### 27. Output: 46.5
- Manual: none
- Tags: 23-94, 19-45, 48
- Rule Path: mixed exact above range
- Explanation: two-range overlap: 23-45; exactAvg 48 > 45; average(48, 45) = 46.5

### 83. Output: 46.83
- Manual: none
- Tags: 41-85
- Rule Path: range-only random pick
- Explanation: single range: 41-85; random pick in 41-85 => 46.83

### 65. Output: 46.95
- Manual: none
- Tags: 69-82, 7-14, 59-81
- Rule Path: range-only random pick
- Explanation: 3+ ranges synthetic range: avg(mins)=45, avg(maxes)=59; random pick in 45-59 => 46.95

### 57. Output: 48.25
- Manual: none
- Tags: 10-21, 72-100, 50
- Rule Path: mixed exact + scalar range result
- Explanation: two-range gap midpoint: (21 + 72) / 2 = 46.5; average(exactAvg=50, scalar=46.5) = 48.25

### 18. Output: 48.75
- Manual: none
- Tags: 86-95, 15, 8
- Rule Path: mixed exact below range
- Explanation: single range: 86-95; exactAvg 11.5 < 86; average(11.5, 86) = 48.75

### 54. Output: 49.5
- Manual: none
- Tags: 42, 67-97, 33-54, 35
- Rule Path: mixed exact + scalar range result
- Explanation: two-range gap midpoint: (54 + 67) / 2 = 60.5; average(exactAvg=38.5, scalar=60.5) = 49.5

### 41. Output: 50
- Manual: 50
- Tags: 64-100, 23-82, 12, 2-50
- Rule Path: manual override
- Explanation: manual priority 50 wins over all tag rules

### 91. Output: 51
- Manual: none
- Tags: 85, 21-70, 29-73, 37-54, 17
- Rule Path: mixed exact inside range
- Explanation: 3+ ranges synthetic range: avg(mins)=29, avg(maxes)=65.67; exactAvg 51 is inside 29-65.67, so exactAvg wins

### 21. Output: 51.5
- Manual: none
- Tags: 83, 62, 34, 27
- Rule Path: exact-only average
- Explanation: average(83, 62, 34, 27) = 51.5

### 28. Output: 53.5
- Manual: none
- Tags: 17, 33-68, 23-27, 90, 55-82
- Rule Path: mixed exact inside range
- Explanation: 3+ ranges synthetic range: avg(mins)=37, avg(maxes)=59; exactAvg 53.5 is inside 37-59, so exactAvg wins

### 89. Output: 54
- Manual: 54
- Tags: 13-37
- Rule Path: manual override
- Explanation: manual priority 54 wins over all tag rules

### 38. Output: 55
- Manual: none
- Tags: 55
- Rule Path: exact-only average
- Explanation: average(55) = 55

### 94. Output: 55
- Manual: none
- Tags: 25, 81, 57-76
- Rule Path: mixed exact below range
- Explanation: single range: 57-76; exactAvg 53 < 57; average(53, 57) = 55

### 35. Output: 55.5
- Manual: none
- Tags: 8, 82-86, 50
- Rule Path: mixed exact below range
- Explanation: single range: 82-86; exactAvg 29 < 82; average(29, 82) = 55.5

### 79. Output: 56
- Manual: none
- Tags: 32-80, 39, 73
- Rule Path: mixed exact inside range
- Explanation: single range: 32-80; exactAvg 56 is inside 32-80, so exactAvg wins

### 62. Output: 56.67
- Manual: none
- Tags: 66, 52, 52, 46-92
- Rule Path: mixed exact inside range
- Explanation: single range: 46-92; exactAvg 56.67 is inside 46-92, so exactAvg wins

### 6. Output: 57.57
- Manual: none
- Tags: 30-76, 15-52, 51-70
- Rule Path: range-only random pick
- Explanation: 3+ ranges synthetic range: avg(mins)=32, avg(maxes)=66; random pick in 32-66 => 57.57

### 56. Output: 57.75
- Manual: none
- Tags: 44, 79-88, 50, 59, 23-50
- Rule Path: mixed exact + scalar range result
- Explanation: two-range gap midpoint: (50 + 79) / 2 = 64.5; average(exactAvg=51, scalar=64.5) = 57.75

### 99. Output: 58
- Manual: 58
- Tags: 57, 8-93, 5, 29
- Rule Path: manual override
- Explanation: manual priority 58 wins over all tag rules

### 45. Output: 58.75
- Manual: none
- Tags: 40-50, 46, 89, 46-80
- Rule Path: mixed exact above range
- Explanation: two-range overlap: 46-50; exactAvg 67.5 > 50; average(67.5, 50) = 58.75

### 63. Output: 59
- Manual: none
- Tags: 55, 19-41, 20-91, 99
- Rule Path: mixed exact above range
- Explanation: two-range overlap: 20-41; exactAvg 77 > 41; average(77, 41) = 59

### 75. Output: 59
- Manual: none
- Tags: 81, 62-75, 83, 4
- Rule Path: mixed exact below range
- Explanation: single range: 62-75; exactAvg 56 < 62; average(56, 62) = 59

### 96. Output: 59
- Manual: none
- Tags: 59, 29-95
- Rule Path: mixed exact inside range
- Explanation: single range: 29-95; exactAvg 59 is inside 29-95, so exactAvg wins

### 98. Output: 59.25
- Manual: none
- Tags: 52-97, 51, 88, 43, 55
- Rule Path: mixed exact inside range
- Explanation: single range: 52-97; exactAvg 59.25 is inside 52-97, so exactAvg wins

### 9. Output: 60
- Manual: none
- Tags: 60
- Rule Path: exact-only average
- Explanation: average(60) = 60

### 25. Output: 60
- Manual: none
- Tags: 84-96, 36
- Rule Path: mixed exact below range
- Explanation: single range: 84-96; exactAvg 36 < 84; average(36, 84) = 60

### 47. Output: 60.5
- Manual: none
- Tags: 55, 66, 42-92
- Rule Path: mixed exact inside range
- Explanation: single range: 42-92; exactAvg 60.5 is inside 42-92, so exactAvg wins

### 24. Output: 62
- Manual: none
- Tags: 88-97, 25-54, 15-22, 64-96, 62
- Rule Path: mixed exact inside range
- Explanation: 3+ ranges synthetic range: avg(mins)=48, avg(maxes)=67.25; exactAvg 62 is inside 48-67.25, so exactAvg wins

### 58. Output: 62
- Manual: none
- Tags: 48-80, 2-46, 12-56, 73-95, 62
- Rule Path: mixed exact inside range
- Explanation: 3+ ranges synthetic range: avg(mins)=33.75, avg(maxes)=69.25; exactAvg 62 is inside 33.75-69.25, so exactAvg wins

### 74. Output: 63.49
- Manual: none
- Tags: 89-95, 8-27, 74-77
- Rule Path: range-only random pick
- Explanation: 3+ ranges synthetic range: avg(mins)=57, avg(maxes)=66.33; random pick in 57-66.33 => 63.49

### 39. Output: 63.75
- Manual: none
- Tags: 71, 76-79, 32
- Rule Path: mixed exact below range
- Explanation: single range: 76-79; exactAvg 51.5 < 76; average(51.5, 76) = 63.75

### 3. Output: 63.84
- Manual: none
- Tags: 51-81, 19-65
- Rule Path: range-only random pick
- Explanation: two-range overlap: 51-65; random pick in 51-65 => 63.84

### 20. Output: 64
- Manual: none
- Tags: 64
- Rule Path: exact-only average
- Explanation: average(64) = 64

### 44. Output: 65.25
- Manual: none
- Tags: 87-89, 94, 15, 61-65
- Rule Path: mixed exact + scalar range result
- Explanation: two-range gap midpoint: (65 + 87) / 2 = 76; average(exactAvg=54.5, scalar=76) = 65.25

### 43. Output: 66.5
- Manual: none
- Tags: 15, 16-83, 82-99, 87
- Rule Path: mixed exact below range
- Explanation: two-range overlap: 82-83; exactAvg 51 < 82; average(51, 82) = 66.5

### 46. Output: 67.66
- Manual: none
- Tags: 78-95, 34, 11-94, 66, 72
- Rule Path: mixed exact below range
- Explanation: two-range overlap: 78-94; exactAvg 57.33 < 78; average(57.33, 78) = 67.66

### 10. Output: 68
- Manual: none
- Tags: 68
- Rule Path: exact-only average
- Explanation: average(68) = 68

### 17. Output: 68
- Manual: none
- Tags: 52, 91, 86, 43
- Rule Path: exact-only average
- Explanation: average(52, 91, 86, 43) = 68

### 51. Output: 68
- Manual: 68
- Tags: 4, 55-67, 15-76, 89
- Rule Path: manual override
- Explanation: manual priority 68 wins over all tag rules

### 26. Output: 70
- Manual: none
- Tags: 16-92, 70, 10-86
- Rule Path: mixed exact inside range
- Explanation: two-range overlap: 16-86; exactAvg 70 is inside 16-86, so exactAvg wins

### 84. Output: 71.34
- Manual: none
- Tags: 62-82, 49, 55-65, 100, 84
- Rule Path: mixed exact above range
- Explanation: two-range overlap: 62-65; exactAvg 77.67 > 65; average(77.67, 65) = 71.34

### 1. Output: 71.41
- Manual: none
- Tags: 11-71, 45, 50-68, 50-75, 98
- Rule Path: mixed exact above range
- Explanation: 3+ ranges synthetic range: avg(mins)=37, avg(maxes)=71.33; exactAvg 71.5 > 71.33; average(71.5, 71.33) = 71.41

### 73. Output: 71.41
- Manual: none
- Tags: 84-97, 13, 40-75, 91, 86
- Rule Path: mixed exact + scalar range result
- Explanation: two-range gap midpoint: (75 + 84) / 2 = 79.5; average(exactAvg=63.33, scalar=79.5) = 71.41

### 68. Output: 71.75
- Manual: none
- Tags: 7-57, 76, 97
- Rule Path: mixed exact above range
- Explanation: single range: 7-57; exactAvg 86.5 > 57; average(86.5, 57) = 71.75

### 67. Output: 72
- Manual: 72
- Tags: 12-65, 94, 68-82, 75
- Rule Path: manual override
- Explanation: manual priority 72 wins over all tag rules

### 69. Output: 75.25
- Manual: none
- Tags: 13-16, 69-90, 83, 29-77, 24-87
- Rule Path: mixed exact above range
- Explanation: 3+ ranges synthetic range: avg(mins)=33.75, avg(maxes)=67.5; exactAvg 83 > 67.5; average(83, 67.5) = 75.25

### 5. Output: 77.84
- Manual: none
- Tags: 91, 88-91, 13, 99
- Rule Path: mixed exact below range
- Explanation: single range: 88-91; exactAvg 67.67 < 88; average(67.67, 88) = 77.84

### 32. Output: 78
- Manual: none
- Tags: 68-85, 78
- Rule Path: mixed exact inside range
- Explanation: single range: 68-85; exactAvg 78 is inside 68-85, so exactAvg wins

### 70. Output: 78.5
- Manual: none
- Tags: 49, 93, 98, 74
- Rule Path: exact-only average
- Explanation: average(49, 93, 98, 74) = 78.5

### 78. Output: 78.75
- Manual: none
- Tags: 92, 35-58, 73-78
- Rule Path: mixed exact + scalar range result
- Explanation: two-range gap midpoint: (58 + 73) / 2 = 65.5; average(exactAvg=92, scalar=65.5) = 78.75

### 33. Output: 79.54
- Manual: none
- Tags: 75-88
- Rule Path: range-only random pick
- Explanation: single range: 75-88; random pick in 75-88 => 79.54

### 14. Output: 81
- Manual: none
- Tags: 81
- Rule Path: exact-only average
- Explanation: average(81) = 81

### 36. Output: 81
- Manual: none
- Tags: 81
- Rule Path: exact-only average
- Explanation: average(81) = 81

### 48. Output: 81
- Manual: 81
- Tags: 50-87, 3-19, 88-92, 22-39
- Rule Path: manual override
- Explanation: manual priority 81 wins over all tag rules

### 2. Output: 82
- Manual: none
- Tags: 82
- Rule Path: exact-only average
- Explanation: average(82) = 82

### 85. Output: 82
- Manual: none
- Tags: 99, 46-65, 44-92
- Rule Path: mixed exact above range
- Explanation: two-range overlap: 46-65; exactAvg 99 > 65; average(99, 65) = 82

### 55. Output: 83
- Manual: none
- Tags: 83
- Rule Path: exact-only average
- Explanation: average(83) = 83

### 81. Output: 83.5
- Manual: none
- Tags: 86-95, 59-81
- Rule Path: range-only scalar result
- Explanation: two-range gap midpoint: (81 + 86) / 2 = 83.5

### 64. Output: 83.65
- Manual: none
- Tags: 47-65, 72-87, 55-99
- Rule Path: range-only random pick
- Explanation: 3+ ranges synthetic range: avg(mins)=58, avg(maxes)=83.67; random pick in 58-83.67 => 83.65

### 88. Output: 83.75
- Manual: none
- Tags: 20-51, 90, 51-83, 18-84, 89-92
- Rule Path: mixed exact above range
- Explanation: 3+ ranges synthetic range: avg(mins)=44.5, avg(maxes)=77.5; exactAvg 90 > 77.5; average(90, 77.5) = 83.75

### 7. Output: 84
- Manual: 84
- Tags: 78-80, 63-84, 22-98, 10-37, 3-65
- Rule Path: manual override
- Explanation: manual priority 84 wins over all tag rules

### 92. Output: 85.5
- Manual: none
- Tags: 68-75, 96
- Rule Path: mixed exact above range
- Explanation: single range: 68-75; exactAvg 96 > 75; average(96, 75) = 85.5

### 82. Output: 87
- Manual: none
- Tags: 82, 74-97, 92
- Rule Path: mixed exact inside range
- Explanation: single range: 74-97; exactAvg 87 is inside 74-97, so exactAvg wins

### 34. Output: 88
- Manual: none
- Tags: 88
- Rule Path: exact-only average
- Explanation: average(88) = 88

### 95. Output: 88
- Manual: 88
- Tags: 45, 43-54, 67-69
- Rule Path: manual override
- Explanation: manual priority 88 wins over all tag rules

### 22. Output: 93.02
- Manual: none
- Tags: 82-99
- Rule Path: range-only random pick
- Explanation: single range: 82-99; random pick in 82-99 => 93.02

### 49. Output: 95.5
- Manual: none
- Tags: 96, 61-95
- Rule Path: mixed exact above range
- Explanation: single range: 61-95; exactAvg 96 > 95; average(96, 95) = 95.5

### 16. Output: 96
- Manual: none
- Tags: 89-98, 96
- Rule Path: mixed exact inside range
- Explanation: single range: 89-98; exactAvg 96 is inside 89-98, so exactAvg wins
