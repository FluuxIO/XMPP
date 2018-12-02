# Development notes

## Cocoapods linting

There is this issue with Cocoapods with Mojave and latest XCode that makes linting fails:
[EXPANDED_CODE_SIGN_IDENTITY: unbound variable](https://github.com/CocoaPods/CocoaPods/issues/7708)

To successfully pass the linting phase before 1.6.0 is released as stable, you can do the following:

```bash
export EXPANDED_CODE_SIGN_IDENTITY=-
export EXPANDED_CODE_SIGN_IDENTITY_NAME=-
pod spec lint
```
