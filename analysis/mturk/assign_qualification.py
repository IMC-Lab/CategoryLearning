#!/usr/bin/python3

import boto3

hit_id = '3S1L4CQSFXN0POKVH1051B89HM9AF3'
qual_id = '33GZEMF8D6LASA841A533VQGC1E7FJ' # for the cat_p qualification

# Create the connection to MTurk
mturk = boto3.client('mturk')

# collect all of the assignments
result = mturk.list_assignments_for_hit(HITId=hit_id,
                                        AssignmentStatuses=['Approved'],
                                        MaxResults=100)
assignments = result['Assignments']
while ('NextToken' in result):
    result = mturk.list_assignments_for_hit(HITId=hit_id, NextToken=result['NextToken'],
                                            AssignmentStatuses=['Approved'],
                                            MaxResults=100)
    assignments = assignments + result['Assignments']


for a in assignments:
    print(a['WorkerId'])
    mturk.associate_qualification_with_worker(QualificationTypeId=qual_id,
                                              WorkerId=a['WorkerId'],
                                              SendNotification=False)
