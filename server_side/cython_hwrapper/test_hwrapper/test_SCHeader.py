import unittest
from header_wrapper import (
    SCHeader,
)

class SCHeaderTest(unittest.TestCase):
    """
    Test the SC_HEADER_t wrapper class.
    """

    def setUp(self):
        """Setup for the tests"""
        print('SCHeaderTest:setUp_:begin')
        self.sch_base = SCHeader()
        self.sch_set = SCHeader()
        self.sch_set.htype = 1
        self.sch_set.hstatus = 2
        self.sch_set.hcode = 3
        self.sch_set.hlength = 4

        print('SCHeaderTest:setUp_:end')

    def tearDown(self):
        """No teardown needed here..."""
        print ('SCHeaderTest:tearDown_:begin')
        print ('SCHeaderTest:tearDown_:end')

    def testBaseValues(self):
        """Test the default values of the wrapper"""
        print ('SCHeaderTest:testBaseValues')
        self.assertEqual(self.sch_base.htype, 0)
        self.assertEqual(self.sch_base.hstatus, 0)
        self.assertEqual(self.sch_base.hcode, 0)
        self.assertEqual(self.sch_base.hlength, 0)

    def testSetValues(self):
        """Set values and test they are set correctly"""
        print ('SCHeaderTest:testSetValues')
        self.assertEqual(self.sch_set.htype, 1)
        self.assertEqual(self.sch_set.hstatus, 2)
        self.assertEqual(self.sch_set.hcode, 3)
        self.assertEqual(self.sch_set.hlength, 4)
