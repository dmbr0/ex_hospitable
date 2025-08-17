ExUnit.start()

# Clear any environment variables that might interfere with tests
System.delete_env("HOSPITABLE_ACCESS_TOKEN")
System.delete_env("HOSPITABLE_BASE_URL")
System.delete_env("HOSPITABLE_TIMEOUT")
System.delete_env("HOSPITABLE_RECV_TIMEOUT")
