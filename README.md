# Translate
## How To Translate ( Test )
- You need to copy the en.yaml file to your language (name is `other.yaml`).
- Example:
```example
cp -r en.yaml -> other.yaml
```
- Next is to translate the `other.yaml` file into your language
- Next copy the translated `languages` folder to /root/
```Example:
cp -r languages /root/
```
- Run proton
```bash
sudo -i
```
```bash
proton
```
- In the language section, select `other`
## How to add the language you translated into the proton repo ?
- **Fork this repo and create a pull request**
