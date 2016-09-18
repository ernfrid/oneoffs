#!/usr/bin/env python

# output should be chromosome, position, unfiltered_depth, filtered_depth, unfiltered_sum, filtered_sum

# expect that the filter should be a BQ of 33
#        r1  r2  r3  r4  r5  r6  r7  r8
#15279   32   0   0   0  32  32  32  32  
#15280   32   0   0   0  32  32  32  37
#15281   37   0   0   0  37  37  0   0
#15282   37   0   0   0  37  0   32  0
#15283   37   0   0   0  37  0   33  0

lines = (
        (1, 15729, (32, 0, 0, 0, 32, 32, 32, 32)),
        (1, 15730, (32, 0, 0, 0, 32, 32, 32, 37)),
        (1, 15731, (37, 0, 0, 0, 37, 37, 0, 0)),
        (1, 15732, (37, 0, 0, 0, 37, 0, 32, 0)),
        (1, 15733, (37, 0, 0, 0, 37, 0, 33, 0)),
        )

for i in lines:
    depth = len([ x for x in i[2] if x > 0])
    q_depth = len([ x for x in i[2] if x >= 33])
    bq_sum = sum([ x for x in i[2]])
    bq_minq_sum = sum([ x for x in i[2] if x >= 33])
    print '\t'.join(map(str, [i[0], i[1], depth, q_depth, bq_sum, bq_minq_sum]))  
