import unittest
from header_wrapper import (
    MHListItem,
    MAX_NAME_LEN,
)

# TODO: test tobytes, frombytes
# TODO: add a comparison operator for the MHListItem class, and other things
#       like copy constructors, etc
class MHListItemTest(unittest.TestCase):
    """
    Test the MH_LIST_ITEM_t wrapper class.
    """

    def setUp(self):
        """Setup for the tests"""
        print('MHListItemTest:setUp_:begin')
        self.mli_base = MHListItem()
        self.mli_set = MHListItem()
        self.mli_set.item_type = 1
        self.mli_set.sc_msg_type = 2
        self.mli_set.name_str = 'steve'
        print('MHListItemTest:setUp_:end')

    def tearDown(self):
        """No teardown needed here..."""
        print ('MHListItemTest:tearDown_:begin')
        print ('MHListItemTest:tearDown_:end')

    def testBaseValues(self):
        """Test the default values of the wrapper"""
        print ('MHListItemTest:testBaseValues')
        self.assertEqual(self.mli_base.item_type, 0)
        self.assertEqual(self.mli_base.sc_msg_type, 0)
        self.assertEqual(self.mli_base.name_str, '')

    def testSetValues(self):
        """Set values and test they are set correctly"""
        print ('MHListItemTest:testSetValues')
        self.assertEqual(self.mli_set.item_type, 1)
        self.assertEqual(self.mli_set.sc_msg_type, 2)
        self.assertEqual(self.mli_set.name_str, 'steve')

    def testNameLenConstraint(self):
        """Set the name to a long string to test the length constraint"""
        print ('MHListItemTest:testNameLenConstraint')
        s = 's' * (MAX_NAME_LEN-1) # account for NULL terminator
        s_long = s + 's'

        self.mli_set.name_str = s_long
        # Make sure the set name is the shorter version (trucation should have
        # happened)
        # TODO: change if trucation behavior is changed
        self.assertEqual(self.mli_set.name_str, s)
