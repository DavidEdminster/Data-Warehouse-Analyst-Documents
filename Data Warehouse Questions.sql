/* 
Project: Data Warehouse Analyst Technical Assessment 
Author: David Edminster
Date: 11/26/2025
*/

/* Question 1. How many dogs were successfully screened? */

with Screened as (
    select sf.id as screen_id
        ,sf.form_completion_date as comp_date
    from [dbo].[Screening_Form] sf
    where sf.form_completion_date is not null
)

select count (screen_id) as Total_Dogs_Screened
from Screened;

/* Answer 1. 12 dogs were successfully screened. */

/* Question 2 Part 1. How many dogs are eligable for screening? */

With Eligable as (
    select sf.id,
        sf.elig_question_1,
        sf.elig_question_2,
        sf.elig_question_3,
        sf.inelig_question_1,
        sf.inelig_question_2
    from [dbo].[Screening_Form] sf
    where (sf.elig_question_1 = 1
        and sf.elig_question_2 = 1
        and sf.elig_question_3 = 1)
        and (sf.inelig_question_1 is not NULL and sf.inelig_question_1 <> 1)
        and (sf.inelig_question_2 is not null and sf.inelig_question_2 <> 1)
)

select count(distinct id) as Count_eligable
 from Eligable

 /* Answer 2 part 1. Only 4 dogs meet the criteria of having "1" for each eligability
  question and also have valid answers for the ineligability questions (non-null), 
  and also not equal to 1. */

  /* Question 2 Part 2. If null values for ineligability do not disqualify,
   the query can be rewritten as follows. */

With Eligable_with_nulls as (
    select sf.id,
        sf.elig_question_1,
        sf.elig_question_2,
        sf.elig_question_3,
        sf.inelig_question_1,
        sf.inelig_question_2
    from [dbo].[Screening_Form] sf
    where (sf.elig_question_1 = 1
        and sf.elig_question_2 = 1
        and sf.elig_question_3 = 1)
        and (sf.inelig_question_1 = 0 or sf.inelig_question_1 is null)
        and (sf.inelig_question_2 = 0 or sf.inelig_question_2 is null) 
)

select count(distinct id) as Count_eligable
 from Eligable_with_nulls

 /* Answer 2 Part 2. When ineligability questions are filtered for 0, or can be null,
 the total eligable count rises to 7 dogs. */

/* Question 3. How many dogs are ready to be enrolled in this study? */

with Eligable as (
    select sf.id,
        sf.elig_question_1,
        sf.elig_question_2,
        sf.elig_question_3,
        sf.inelig_question_1,
        sf.inelig_question_2
    from [dbo].[Screening_Form] sf
    where (sf.elig_question_1 = 1
        and sf.elig_question_2 = 1
        and sf.elig_question_3 = 1)
        and (sf.inelig_question_1 is not NULL and sf.inelig_question_1 <> 1)
        and (sf.inelig_question_2 is not null and sf.inelig_question_2 <> 1)
)

select e.id,
    wdf.withdrawal_status,
    count(e.id) over (partition by withdrawal_status) as total_ready
from Eligable e
left join [dbo].[Request_to_Withdraw_Form] wdf
    on e.id = wdf.id
GROUP by e.id, wdf.withdrawal_status

/* Answer 3. The total eligable dogs is 4, and the left join pulls out the associated values for the withdrawal status.
We see that there are no dog ID's who are were eligable to be enrolled in the study, who also indicated a 1 or 2 in withdrawal status. 
The dogs with ID's 4, 5, 40, and 58 are eligable, whereas dogs whose ID's are 2, or 25 indicated they are withdrawn. */

/* Question 4. How many dogs were withdrawn from the study? */

with Withdrawn as (
    select pi.id,
        pi.name,
        wdf.withdrawal_status
    from dbo.participant_info as pi
    inner join dbo.Request_to_Withdraw_Form as wdf
        on pi.id = wdf.id
        and wdf.withdrawal_status in (1, 2)
)
select 
    sum(counts) as totals
from(
    select 
    count(id) as [counts]
    from Withdrawn 
    ) as totals 

/* Answer 4. Of the total dogs participating (14), 2 withdrew. Starting from the participant info table to get all ID's available, 
and then using an inner join to correspond ID's, 
filtering in the join for only those whose withdrawal status is 1 or 2. */

/* Question 5. How many screened dogs are over 5? */

with age_over_5 as (
    select sf.id,
            pi.date_of_birth
    from [dbo].[Screening_Form] sf
    inner join [dbo].participant_info as pi 
        on sf.id = pi.id
    where pi.date_of_birth < dateadd(year, -5, getdate())
)

select count(id) as total_over_5
 from age_over_5

/* Answer 5. There are a total of 9 dogs who were screened and whose birthdays are greateer than 5 years from the current day. */

/* Question 6. Contact those who are eligable to be enrolled in the order sorted by oldest form completion date */

with enrollable as (
    select sf.id,
        sf.elig_question_1,
        sf.elig_question_2,
        sf.elig_question_3,
        sf.inelig_question_1,
        sf.inelig_question_2,
        sf.form_completion_date,
        wdf.withdrawal_status
    from [dbo].[Screening_Form] sf
    left join dbo.request_to_withdraw_form wdf
        on sf.id = wdf.id
    where (sf.elig_question_1 = 1
        and sf.elig_question_2 = 1
        and sf.elig_question_3 = 1)
        and (sf.inelig_question_1 is not NULL and sf.inelig_question_1 <> 1)
        and (sf.inelig_question_2 is not null and sf.inelig_question_2 <> 1)
)

select e.id,
        e.form_completion_date,
    rank() over (ORDER by form_completion_date asc) as Contact_order
from enrollable e

/* Answer 6. Of the 4 dogs who met the prior established critera for enrollment eligability, 
a rank is created based on when the form was completed, with the oldest form contacted first. */
