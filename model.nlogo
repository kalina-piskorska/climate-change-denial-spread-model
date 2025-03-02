;Setting up the population
breed [believers believer]; The individuals with certain climate change beliefs


;Setting up variables specific for each individual (believer)
believers-own[
  initial_belief; Represents the randomly (within normal distribution) value of what a person initially believes - how high is their belief in climate change
  state; Represents the value of a person's belief after interactions with others and media
  trust_modifier_denial_media; A binary variable that represents if an individual (believer) is influenced by denialist media or not - depending on their state (belief)
  trust_modifier_proclimate_media; A binary variable that represents if an individual (believer) is influenced by pro-climate media or not - depending on their state (belief)
  influence_denial_media; Represents the general influence of denialist media on the individual's belief, calculated based on the general trust of the population in denial media and an individual's trust_modifier_denial_media
  influence_proclimate_media; Represents the general influence of pro-climate media on the individual's belief, calculated based on the general trust of the population in pro-climate media and an individual's trust_modifier_proclimate_media
  n_influence; Represents the influence other agents linked to the individual have, calculated as the average of the states of connected agents with influence (per round/tick)
  neighbor_count; Saves the number of agents connected to the individual per round (tick)
  influence_others; Represents the general influence of other agents on an individual
]


;Setting up global variables (for normalization)
globals[
  total_weights; Sum of influence factors from the sliders on the interface for normalizing belief updates
  own_belief_confidence_n; Normalized weight of an individual's initial belief
  trust_others_n; Normalized weight of influence from neighbors
  influence_denial_media_n; Normalized weight of influence from denialist media
  influence_proclimate_media_n; Normalized weight of influence from pro-climate media
]


to setup
  clear-all
  reset-ticks

  ; Spawn believers at random patches(number of believers regulated by slider on the interface)
  ask n-of number_of_people patches[
  sprout-believers 1 [
    set shape "person"
]
]

  ask believers [
    set initial_belief clamp-normal-value; Assign initial belief using a normal distribution
    set color (ifelse-value ; Assign color based on belief level
      initial_belief <= 0.2  [25] ; More red colors for lower beliefs
      initial_belief <= 0.4  [35] ; -> brown
      initial_belief <= 0.6  [45] ; -> yellow
      initial_belief <= 0.8  [55] ; -> light green
      initial_belief <= 1  [75]; Greener colors for stronger beliefs
      [white])
    setxy random-xcor random-ycor; Randomly place believers in the environment
    ]
end


; Function to generate a belief value within the normal distribution
to-report clamp-normal-value
  let normal-value random-normal avg_initial_belief std_initial_belief; Use average and standard deviation from the sliders on the interface
  report min list 1 (max list 0 normal-value); Ensure value is between 0 and 1
end


to go
  ;Clearing all connections with other agents before starting the next round/tick
  clear-links

  ask believers [

    if ticks = 0 [set state initial_belief]; Set initial state on the first tick

    ; Reset variables for the new round
    set n_influence 0
    set neighbor_count 0

    ; Identify nearby agents within a given distance, use distance_links and num_links from variable sliders (interface)
    let nearby_agents other believers in-radius distance_links
    let chosen_partners n-of (min list num_links count nearby_agents) nearby_agents


    ; Establish connections with selected partners (if not already linkes)
    ask chosen_partners [
      if not link-neighbor? myself[
        create-link-with myself
      ]
    ]

    ; Process links and update influence based on belief similarity, use accept_states_distance_others from a slider (interface)
    ask my-links [
      let neighbor other-end
      let state-diff abs ([state] of neighbor - [state] of myself)
      ifelse state-diff < accept_states_distance_others [
        set color pink; Color connection pink if belief difference allows for mutual influence (smaller than the threshold)
        ask turtle ([who] of myself) [
          set n_influence n_influence + [state] of neighbor; Add the influence
          set neighbor_count neighbor_count + 1
        ]
      ] [
        set color gray; Color connection gray if belief difference does not allow for mutual influence on beliefs (bigger than the threshold)
      ]
    ]


; Optional line for monitoring influence of others:
;    print (word "n_influence (before normalization) for believer " who ": " n_influence)


    ; Normalize influence from neighbors
    ifelse neighbor_count > 0 [
      set n_influence n_influence / neighbor_count]
    [set n_influence n_influence + 0]]


; Optional lines for monitoring influence of others:
;  print (word "Neighbor count for believer " who ": " neighbor_count)
;  print (word "Final n_influence for believer " who ": " n_influence)



  ; Update belief state based on media influence and social connections
  ask believers [
    ; Ensure influence values stay within valid range 0-1
    set n_influence max list 0 (min list 1 n_influence)

  if any? my-links [
    if ticks > 0 [
        ; Determine trust in media based on belief level, use the threshold accept_states_distance_media from a slider (interface)
        ifelse abs (state - 0) < accept_states_distance_media[
          set trust_modifier_denial_media 1]
         [set trust_modifier_denial_media 0]

        ifelse abs (state - 1) < accept_states_distance_media[
          set trust_modifier_proclimate_media 1]
        [set trust_modifier_proclimate_media 0]

        ; Compute media influence values, including general population level trust in media (sliders)
        set influence_denial_media trust_modifier_denial_media * trust_denial_media
        set influence_proclimate_media trust_modifier_proclimate_media * trust_proclimate_media

        ; Define influence_others - set to 0 if there were no influential social connections
        ifelse neighbor_count = 0 [
          set influence_others 0]
        [set influence_others trust_others]

        ; Normalize weight factors for belief calculation
        set total_weights own_belief_confidence + influence_others + influence_denial_media + influence_proclimate_media
        set own_belief_confidence_n own_belief_confidence / total_weights
        set trust_others_n influence_others / total_weights
        set influence_denial_media_n influence_denial_media / total_weights
        set influence_proclimate_media_n influence_proclimate_media / total_weights


        ; Update belief state using weighted influence
        set state (own_belief_confidence_n * state + trust_others_n * n_influence + 0 * influence_denial_media_n + 1 * influence_proclimate_media_n)]]


    ; Ensure state remains within the range [0, 1]
        set state max list 0 (min list 1 state)

    ; Update color based on new belief state
    set color (ifelse-value
      state <= 0.2 [25] ; Dark orange for the lowest belief
      state <= 0.4 [35]
      state <= 0.6 [45]
      state <= 0.8 [55]
      state <= 1   [75] ; Dark green for the highest belief
      [white])
  ]


; Advance simulation by one tick
tick

end
@#$#@#$#@
GRAPHICS-WINDOW
309
123
708
523
-1
-1
12.613
1
10
1
1
1
0
0
0
1
-15
15
-15
15
1
1
1
ticks
30.0

BUTTON
468
74
531
107
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
398
74
461
107
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
19
376
203
409
num_links
num_links
0
10
2.0
1
1
NIL
HORIZONTAL

SLIDER
14
132
245
165
own_belief_confidence
own_belief_confidence
0
1
0.2
0.1
1
NIL
HORIZONTAL

BUTTON
540
74
617
107
go once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
745
127
1362
434
information on the count of climate change denialists
ticks
number of people
0.0
3.0
0.0
60.0
true
true
"" ""
PENS
"climate change belief lower than 0.20" 1.0 0 -955883 true "" "plot count turtles with [color =  25]"
"climate change belief 0.21-0.4" 1.0 0 -6459832 true "" "plot count turtles with [color =  35]"
"climate change belief 0.41-0.6" 1.0 0 -1184463 true "" "plot count turtles with [color =  45]"
"climate change belief 0.61-0.8" 1.0 0 -10899396 true "" "plot count turtles with [color =  55]"
"climate change belief 0.81-1" 1.0 0 -14835848 true "" "plot count turtles with [color =  75]"

MONITOR
820
448
1024
493
number of people with belief < 0.2
count turtles with [color = 25]
17
1
11

MONITOR
822
507
1043
552
number of people with belief 0.21-0.4
count turtles with [color =  35]
17
1
11

MONITOR
821
567
1042
612
number of people with belief 0.41-0.6
count turtles with [color = 45]
17
1
11

MONITOR
822
622
1043
667
number of people with belief 0.61-0.8
count turtles with [color = 55]
17
1
11

MONITOR
823
675
1033
720
number of people with belief 0.81-1
count turtles with [color =  75]
17
1
11

MONITOR
386
539
460
584
avg state
mean [state] of  believers
4
1
11

MONITOR
1724
249
1822
294
avg initial belief
mean [initial_belief] of believers
4
1
11

MONITOR
1724
308
1819
353
std initial belief
standard-deviation [initial_belief] of believers
4
1
11

MONITOR
497
541
560
586
std state
standard-deviation [state] of believers
4
1
11

SLIDER
20
334
192
367
distance_links
distance_links
0
60
6.0
1
1
NIL
HORIZONTAL

SLIDER
21
596
193
629
avg_initial_belief
avg_initial_belief
0
1
0.1
0.1
1
NIL
HORIZONTAL

SLIDER
21
641
193
674
std_initial_belief
std_initial_belief
0
1
0.3
0.1
1
NIL
HORIZONTAL

PLOT
1702
409
2027
657
avg and std of state
ticks
units
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"mean of state" 0.01 0 -14070903 true "" "plot mean [state] of  believers"
"std of state" 0.01 0 -2064490 true "" "plot standard-deviation [state] of  believers"

PLOT
1710
868
1910
1019
average distances
ticks
avg distance
0.0
1.0
0.0
1.0
true
false
"" ""
PENS
"pen-4" 1.0 0 -14835848 true "" "plot average-distance-between-color 75"

SLIDER
1650
805
1822
838
number_of_people
number_of_people
0
100
100.0
1
1
NIL
HORIZONTAL

PLOT
1931
870
2131
1020
plot 1
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -10899396 true "" "plot average-distance-between-color 55"

PLOT
1709
1052
1909
1202
plot 2
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -1184463 true "" "plot average-distance-between-color 45"

PLOT
1922
1053
2122
1203
plot 3
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -6459832 true "" "plot average-distance-between-color 35"

PLOT
2014
896
2214
1046
plot 4
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -955883 true "" "plot average-distance-between-color 25"

PLOT
1836
172
2178
357
average distances for all colors
ticks
distance
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"0.81-1" 1.0 0 -14835848 true "" "plot average-distance-between-color 75"
"0.61-0.8" 1.0 0 -10899396 true "" "plot average-distance-between-color 55"
"0.41-0.6" 1.0 0 -1184463 true "" "plot average-distance-between-color 45"
"0.21-0.4" 1.0 0 -6459832 true "" "plot average-distance-between-color 35"
"0-0.2" 1.0 0 -955883 true "" "plot average-distance-between-color 25"

SLIDER
16
173
235
206
trust_others
trust_others
0
1
0.1
0.1
1
NIL
HORIZONTAL

SLIDER
14
256
260
289
trust_denial_media
trust_denial_media
0
1
0.1
0.1
1
NIL
HORIZONTAL

SLIDER
15
216
266
249
trust_proclimate_media
trust_proclimate_media
0
1
0.1
0.1
1
NIL
HORIZONTAL

SLIDER
18
461
256
494
accept_states_distance_others
accept_states_distance_others
0
1
1.0
0.1
1
NIL
HORIZONTAL

SLIDER
18
504
241
537
accept_states_distance_media
accept_states_distance_media
0
1
1.0
0.1
1
NIL
HORIZONTAL

MONITOR
1647
690
1882
735
avg state 0.81-1
mean [state] of  believers with [color = 75]
17
1
11

MONITOR
1649
752
1848
797
avg state 0-0.2
mean [state] of  believers with [color = 25]
17
1
11

TEXTBOX
20
107
170
125
TRUST PARAMETERS
11
0.0
1

TEXTBOX
21
309
171
327
LINKS PARAMETERS
11
0.0
1

TEXTBOX
23
435
217
463
OPINION DISTANCE THRESHOLDS
11
0.0
1

TEXTBOX
23
572
173
590
DISTRIBUTION PARAMETERS
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
