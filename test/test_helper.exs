# Set a flag to indicate we're in test mode
Process.put(:in_test, true)

# Set default timeout of 1 second for all tests
ExUnit.start(timeout: 1000)
