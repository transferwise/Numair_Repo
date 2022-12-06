WITH CTE AS (
    SELECT DISTINCT PMT.TRANSFER_ID,COALESCE(PCL.PAYOUT_CLASSIFICATION,PMT.PAYOUT_CLASSIFICATION) AS TRANSFER_STATE
    FROM REPORTS.PKR_DOUBLE_PAYOUT_MASTER_TABLE PMT
    LEFT JOIN  REPORTS.PKR_DOUBLE_PAYOUT_CHANGE_LOG PCL ON PCL.TRANSFER_ID = PMT.TRANSFER_ID

),

DOUBLE_PAYOUTS AS (SELECT
DISTINCT CTE.TRANSFER_ID AS TRANSFER_ID,
LAST_VALUE(CTE.TRANSFER_STATE) OVER (PARTITION BY CTE.TRANSFER_ID ORDER BY LAST_UPDATED) AS TRANSFER_STATE,
LAST_VALUE(WI.STATE) OVER (PARTITION BY CTE.TRANSFER_ID ORDER BY LAST_UPDATED) AS WORK_ITEM_STATE,
LAST_VALUE(INVOICE_VALUE_GBP) OVER (PARTITION BY CTE.TRANSFER_ID ORDER BY LAST_UPDATED) AS AMOUNT_IN_GBP,
LAST_VALUE(CURRENCY_CODE) OVER (PARTITION BY CTE.TRANSFER_ID ORDER BY LAST_UPDATED) AS CURRENCY,
LAST_VALUE(WI.LAST_UPDATED ) OVER (PARTITION BY CTE.TRANSFER_ID ORDER BY LAST_UPDATED) AS LAST_UPDATED,
LAST_VALUE(PKRC.CATEGORY) OVER (PARTITION BY CTE.TRANSFER_ID ORDER BY LAST_UPDATED) AS CATEGORY,
LAST_VALUE(PKRC.NOTIFICATION_CATEGORY) OVER (PARTITION BY CTE.TRANSFER_ID ORDER BY LAST_UPDATED) AS NOTIFICATION_CATEGORY,
LAST_VALUE(PKRC.PAYIN_CHANNEL) OVER (PARTITION BY CTE.TRANSFER_ID ORDER BY LAST_UPDATED) AS PAYIN_CHANNEL ,
LAST_VALUE(IFF(WI.STATE = 'CLOSED',WI.LAST_UPDATED,NULL) ) OVER (PARTITION BY CTE.TRANSFER_ID ORDER BY LAST_UPDATED) AS DATE_CLOSED
FROM CTE
         INNER JOIN FX.WORK_ITEM WI ON WI.REQUEST_ID = CTE.TRANSFER_ID
         INNER JOIN REPORTS.REPORT_ACTION_STEP RAS ON RAS.REQUEST_ID = CTE.TRANSFER_ID
         LEFT JOIN  REPORTS.PKR_DOUBLE_PAYOUT_CLASSIFICATION PKRC ON PKRC.TRANSFER_ID = CTE.TRANSFER_ID
WHERE TRUE
 AND RAS.NOT_DUPLICATE = 1
 AND WI.TYPE = 'PROBLEMATIC_OOPS'
 AND CTE.TRANSFER_STATE = 'DPO'),

-- PARTIAL RECOVERY LOGIC 


PARTIAL_RECOVERIES AS (

SELECT DP.*,BT.AMOUNT as RECOVERED_AMOUNT, BT.CURRENCY AS RECOVERED_CURRENCY
FROM DOUBLE_PAYOUTS DP
INNER JOIN FX.BANK_TRANSACTION_LINK BTL
    ON DP.TRANSFER_ID = BTL.REQUEST_ID
INNER JOIN BSS.BANK_TRANSACTION BT
    ON BT.id = BTL.BANK_TRANSACTION_ID
WHERE TRUE
AND BTL.LINK_TYPE = 'RECEIVE'
AND BTL.REVIEWED_BY_ID !=236988
AND WORK_ITEM_STATE != 'CLOSED')

/*
 1. THERE ARE RECORDS WHERE RECOVERED AMOUNT = TOTAL BUT THESE ARE NOT CLOSED YET
 2. RECORDS WHERE RECOVERED AMOUNT > TOTAL AMOUNT
 */


SELECT * FROM PARTIAL_RECOVERIES