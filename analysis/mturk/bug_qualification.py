#!/usr/bin/python3

import boto3

hit_id = '3DZKABX2ZINDE03J1U10PS1J52DVCB'
qual_id = '3RM888DJP7Q369BYVYO874981LY2F4' # for the categorization_bug_reimbursment qualification

# Create the connection to MTurk
mturk = boto3.client('mturk')

r = mturk.list_workers_with_qualification_type(QualificationTypeId=qual_id, MaxResults=100)
a = [x['WorkerId'] for x in r['Qualifications']]
print('There are ' + str(len(a)) + ' workers with the qualification.')
print(a)
quit()

imlindakim7777@gmail.com
justin.niernberger@gmail.com
kerri.spaziano@yahoo.com
koltredamazon@yahoo.com
lorizawadzki@hotmail.com
lizarrag@sbcglobal.net

# workerIDs of people that emailed
workerIDs = ['A2GXHECU31O81V',
             'A3BTV0RLP0LTO8',
             'A377LTGWJKY2IW',
             'A38W8NZH4DJCDP',
             'A3CWEN6Y21V7TL',
             'A1PJUYJ7W2LKKQ',
             'A3V4VZRRGBW0BO',
             'AVPKE76DJLWK6',
             'A3POD149IG0DIW',
             'A1YSYI926BBOHW',
             'A1DNJ17PE2RYJZ',
             'A1RCQT5Z8PHTWJ',
             'ABUF5EN8YNJQO',
             'A1BAPMRIU7SGSP',
             'A3CWEN6Y21V7TL']

# collect all of the assignments
result = mturk.list_assignments_for_hit(HITId=hit_id, MaxResults=100)
assignments = result['Assignments']
while ('NextToken' in result):
    result = mturk.list_assignments_for_hit(HITId=hit_id, NextToken=result['NextToken'],
                                            MaxResults=100)
    assignments = assignments + result['Assignments']

# remove any workerIDs that have completed assignments
for a in assignments:
    while (a['WorkerId'] != 'A3BTV0RLP0LTO8'
           and a['WorkerId'] in workerIDs):
        print('removing: ' + a['WorkerId'])
        workerIDs.remove(a['WorkerId'])
print(workerIDs)


# assign the remaining workers to the qualification
#for workerID in workerIDs:
#    print(workerID)
#    mturk.associate_qualification_with_worker(QualificationTypeId=qual_id,
#                                              IntegerValue=1,
#                                              WorkerId=workerID)
