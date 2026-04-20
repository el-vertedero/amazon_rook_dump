SEINF1_FRM_CNTR='/d/seninf_events/seninf1/frame_cntr'
SEINF1_PKT_FRM_CNTR='/d/seninf_events/seninf1/pkt_frame_cntr'
SEINF1_FRM_CNTR='/d/seninf_events/seninf1/frame_cntr'
SEINF1_CRC_ERR='/d/seninf_events/seninf1/crc_err'
SEINF1_ECC_SINGLE='/d/seninf_events/seninf1/ecc_single'
SEINF1_ECC_DOUBLE='/d/seninf_events/seninf1/ecc_double'

SEINF2_FRM_CNTR='/d/seninf_events/seninf2/frame_cntr'
SEINF2_PKT_FRM_CNTR='/d/seninf_events/seninf2/pkt_frame_cntr'
SEINF2_CRC_ERR='/d/seninf_events/seninf2/crc_err'
SEINF2_ECC_SINGLE='/d/seninf_events/seninf2/ecc_single'
SEINF2_ECC_DOUBLE='/d/seninf_events/seninf2/ecc_double'

echo "***************************************************"
echo "            SENINF MIPI Error Report               "
echo "*****************SENINF 1 (RFC)*********************"
echo "frames:" $(cat $SEINF1_FRM_CNTR)
echo "pkt_frame_num:" $(cat $SEINF1_PKT_FRM_CNTR)
echo "crc:" $(cat $SEINF1_CRC_ERR)
echo "ecc_double:" $(cat $SEINF1_ECC_DOUBLE)
echo "ecc_single" $(cat $SEINF1_ECC_SINGLE)
echo "*****************SENINF 2 (FFC)*********************"
echo "frames:" $(cat $SEINF2_FRM_CNTR)
echo "pkt_frame_num:" $(cat $SEINF2_PKT_FRM_CNTR)
echo "frames:" $(cat $SEINF2_FRM_CNTR)
echo "crc:" $(cat $SEINF2_CRC_ERR)
echo "ecc_double:" $(cat $SEINF2_ECC_DOUBLE)
echo "ecc_single" $(cat $SEINF2_ECC_SINGLE)
echo "***************************************************"

