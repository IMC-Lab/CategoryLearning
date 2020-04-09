#!/usr/local/bin/python3

import boto3
import pandas as pd

AMOUNT=1.00

# Create the connection to MTurk
mturk = boto3.client('mturk')

df = pd.read_csv('bonus.csv')
total = 0.0

# assign the cat_p qualification and pay bonuses
for index, row in df.iterrows():
    total = total + AMOUNT
    print(row['WorkerId'] + ': ' + str(AMOUNT))
    mturk.send_bonus(WorkerId=row['WorkerId'],
                     AssignmentId=row['AssignmentId'],
                     BonusAmount=str(AMOUNT),
                     Reason='You are receiving this bonus payment because you had above 85% memory accuracy on our flower categorization and memory task.')
print('TOTAL: ' + str(total))
