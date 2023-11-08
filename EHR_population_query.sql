#This IS our main 

SELECT ICD10_COD 
from ths_diagnosis td ;

# Q1:find study pop of people with diabetes mellitus (any type first)
# ICD10 code for diabetes mellitus type 1 = E10%
# ICD10 code for diabetes mellitus type 2 = E11%
# check in main diagnosis for hospitalization OR long-term illness OR associated diagnosis OR at least one dispensed drug metformin (ATC code A10BA02 or A10BD% for combinations of metformin and other)

# first look in main hospitalization 
select PAT_ID , HOSP_MAIN_DGN
from tab_hospitalisation th
where HOSP_MAIN_DGN  like 'E10%'OR  HOSP_MAIN_DGN like 'E11%';
group by PAT_ID;
# n = 6900

select distinct HOSP_MAIN_DGN
from tab_hospitalisation th
where HOSP_MAIN_DGN  like 'E10%'OR  HOSP_MAIN_DGN like 'E11%';
# we have 4 codes for diabetes mellitus type 1 (E101, E103, E104 and E109) and two for diabetes mellitus type 2 (E114 and E119)

# then check in long-term illness
select PAT_ID, LTI_ICD_REASON
from tab_long_term_illness tlti 
where LTI_ICD_REASON  like 'E10%'OR  LTI_ICD_REASON  like 'E11%';
group by PAT_ID;
# n = 3017

select distinct LTI_ICD_REASON 
from tab_long_term_illness tlti 
where LTI_ICD_REASON  like 'E10%'OR  LTI_ICD_REASON  like 'E11%';
# now we have from E10 to E109 for diabetes type 1 and from E11 to E119 for diabetes type 2 (all of them basically)

# then check in associated diagnosis
select PAT_ID , DGN_ASS
from tab_mso_ass_dgn mad inner join tab_hospitalisation th
where (th.RSA_NUM = mad.RSA_NUM and th.ETA_NUM = mad.ETA_NUM) 
and (DGN_ASS like 'E10%' or DGN_ASS like 'E11%');
# n = 44,550 


CREATE TEMPORARY TABLE temp_ass_diagnosis_diabetes_patientss as 
select PAT_ID , DGN_ASS, HOSP_START_DATE , HOSP_END_DATE 
from tab_mso_ass_dgn mad inner join tab_hospitalisation th
where (th.RSA_NUM = mad.RSA_NUM and th.ETA_NUM = mad.ETA_NUM) 
and (DGN_ASS like 'E10%' or DGN_ASS like 'E11%');

SELECT MIN(HOSP_START_DATE) as start_cohort, MAX(HOSP_END_DATE) as end_cohort
from temp_ass_diagnosis_diabetes_patientss
# can be the range of our cohort (defined as people with diabetes 1 or 2 based only on associated diagnosis here)



# check in patient who had at least one dispensed drug metformin (ATC code A10BA02 or A10BD%)
select tp2.PAT_ID, COUNT(*) as nb_dispensed
from tab_patient tp, tab_prescription tp2, tab_prs_drugs tpd, ths_drugs td 
where tp.PAT_ID  = tp2.PAT_ID 
and tp2.PRS_KEY = tpd.PRS_KEY
and tpd.DRUG_CIP7 = td.DRUG_CIP7  
and (DRUG_ATC_C07 = 'A10BA02' or  DRUG_ATC_C07 like 'A10BD%')
GROUP BY tp2.PAT_ID 
having nb_dispensed >= 1
# n = 5616


# EXPOSURE 
# Q1: Patients who have taken anti-diabetic blood glucose lowering drugs excluding insulin (ATC code like A10B%) but not combinations 
select tp2.PAT_ID , DRUG_ATC_C07
from tab_patient tp, tab_prescription tp2, tab_prs_drugs tpd, ths_drugs td 
where tp.PAT_ID  = tp2.PAT_ID 
and tp2.PRS_KEY = tpd.PRS_KEY
and tpd.DRUG_CIP7 = td.DRUG_CIP7  
and DRUG_ATC_C07 like 'A10B%'
and DRUG_ATC_C07 not like 'A10BD%';
# n = 195,660


select tp.PAT_ID, DRUG_ATC_C07, count(*) as count_per_patient
from tab_patient tp, tab_prescription tp2, tab_prs_drugs tpd, ths_drugs td 
where tp.PAT_ID  = tp2.PAT_ID 
and tp2.PRS_KEY = tpd.PRS_KEY
and tpd.DRUG_CIP7 = td.DRUG_CIP7 
and DRUG_ATC_C07 like 'A10B%'
and DRUG_ATC_C07 not like 'A10BD%'
group by tp.PAT_ID ;


select tp.PAT_ID, DRUG_ATC_C07, count(*) as count_per_patient_and_drug
from tab_patient tp, tab_prescription tp2, tab_prs_drugs tpd, ths_drugs td 
where tp.PAT_ID  = tp2.PAT_ID 
and tp2.PRS_KEY = tpd.PRS_KEY
and tpd.DRUG_CIP7 = td.DRUG_CIP7  
and DRUG_ATC_C07 like 'A10B%'
and DRUG_ATC_C07 not like 'A10BD%'
group by tp.PAT_ID, DRUG_ATC_C07;


select unique DRUG_ATC_C07
from tab_patient tp, tab_prescription tp2, tab_prs_drugs tpd, ths_drugs td 
where tp.PAT_ID  = tp2.PAT_ID 
and tp2.PRS_KEY = tpd.PRS_KEY
and tpd.DRUG_CIP7 = td.DRUG_CIP7  
and DRUG_ATC_C07 like 'A10B%' 
and DRUG_ATC_C07 not like 'A10BD%';
# n=14 different blood glucose lowering drugs of the categories 
# biguanides: only metformin
# sulfonylureas: glizipide, gliclazide, glimepiride
# alpha glucosidase inhibitors: acarbose, miglitol
# DDP-4 inhibitors: sitagliptin, vildagliptin, saxagliptin
# other blood glucose lowering drugs, excluding insulins: repaglinide,exenatide,  liraglutide, dulaglutid



#Checking main diagnosis in tab_hospitalisation (no results) need to check in ass diagnosis
select unique HOSP_MAIN_DGN
from tab_hospitalisation th  
where HOSP_MAIN_DGN in (
select ICD10_COD
FROM ths_diagnosis td 
where ICD_TXT_ENG like '%dE11iab%' );

select unique HOSP_MAIN_DGN
from tab_hospitalisation th  
where HOSP_MAIN_DGN in (
select ICD10_COD
FROM ths_diagnosis td 
where ICD_TXT_ENG like '%thrombosis%' );

select unique HOSP_MAIN_DGN
from tab_hospitalisation th  
where HOSP_MAIN_DGN in (
select ICD10_COD
FROM ths_diagnosis td 
where ICD_TXT_ENG like '%embolism%' );

select unique HOSP_MAIN_DGN
from tab_hospitalisation th  
where HOSP_MAIN_DGN in (
select ICD10_COD
FROM ths_diagnosis td 
where ICD_TXT_ENG like '%thromboembolism%' );



--------



#Checking associated diagnoses in tab_mso_ass_dgn

# NOTE MARIANE: would you need the "where" clause to be both RSA_NUM and ETA_NUM since they are both together the primary key?
# NOTE 2 MARIANE: you don't actually need to look in the ths_diagnosis for ICD10_CODE since DGN_ASS and HOSP_MAIN_DGN are both ICD codes too
# you can just do this 
select DGN_ASS, HOSP_MAIN_DGN
from tab_mso_ass_dgn mad inner join tab_hospitalisation th
where (th.RSA_NUM = mad.RSA_NUM and th.ETA_NUM = mad.ETA_NUM)
and DGN_ASS like 'I80%'; # same for the other 



#n = 421 hospitalisations of VTE
select DGN_ASS, HOSP_MAIN_DGN
from tab_mso_ass_dgn mad inner join tab_hospitalisation th
where th.RSA_NUM = mad.RSA_NUM
and DGN_ASS in (
select ICD10_COD
FROM ths_diagnosis td 
where ICD10_COD like 'I80%' );

#of those 421 hospitalisations, n = 22 distinct patients
select unique th.PAT_ID
from tab_mso_ass_dgn mad inner join tab_hospitalisation th
where th.RSA_NUM = mad.RSA_NUM
and DGN_ASS in (
select ICD10_COD
FROM ths_diagnosis td 
where ICD10_COD like 'I80%' );

#need to find patients who have procedures related to DVT in tab_mso_procedures (unfinished query, haven't found all CCAM codes for DVT) maybe we should also find patients who have procedures related to PE? 
select unique RSA_NUM
from tab_mso_procedures tmp
where PROC_COD in (
select PROC_COD
FROM ths_procedures td 
where PROC_COD like 'EJQM00%' );