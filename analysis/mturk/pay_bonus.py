#!/usr/bin/python3

import boto3
import xmltodict

hit_id = '3DZKABX2ZINDE03J1U10PS1J52DVCB'
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

print(len(assignments))
quit()
    
# assign the cat_p qualification and pay bonuses
for a in assignments:
    print(a['WorkerId'])
    mturk.associate_qualification_with_worker(QualificationTypeId=qual_id,
                                              WorkerId=a['WorkerId'],
                                              IntegerValue=1,
                                              SendNotification=False)
    print(a['Answer'])
    
    #results = xmltodict.parse(a['Answer'])
    #for answer_field in results('QuestionFormAnswers'):
    #    print('For input field: ' + answer_field['QuestionIdentifier'])
    #    print('Response: ' + answer_field['FreeText'])
    quit()
