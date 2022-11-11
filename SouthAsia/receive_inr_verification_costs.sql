/*
 Author: Numair Fazili
 Last Modified: 16/11/2022
 Description: Verification costs for receive INR customers
 */

SELECT VERIFICATION_METHOD,
       COUNT(DISTINCT verification_user_cost.USER_PROFILE_ID) AS TOTAL_PROFILES,
       sum(cost) AS COSTS,
       SUM(COALESCE(TOTAL_COST_WITH_OVERHEAD,COST)) AS COSTS_WITH_OVERHEADS -- TOTAL_COST_WITH_OVERHEAD >= COST (can also be nULL)
FROM
    REPORTS.REGIONAL_USER_PROFILE_CHARACTERISTICS AS user_profile
INNER JOIN reports.verification_user_cost AS verification_user_cost
    ON verification_user_cost.USER_PROFILE_ID = user_profile.USER_PROFILE_ID
INNER JOIN DEPOSITACCOUNT.DEPOSIT_ACCOUNT  AS DA
    ON DA.profile_id = user_profile.USER_PROFILE_ID
INNER JOIN DEPOSITACCOUNT.BANK  AS DAB
    ON DAB.ID = DA.BANK_ID
WHERE TRUE
AND UPPER(user_profile.COUNTRY_CODE_3_CHAR) = 'IND'
AND UPPER(user_profile.CUSTOMER_CLASS) = 'BUSINESS'
AND UPPER(DAB.CURRENCY) IN ('USD','EUR','GBP')
GROUP BY VERIFICATION_METHOD
ORDER BY TOTAL_PROFILES DESC;


