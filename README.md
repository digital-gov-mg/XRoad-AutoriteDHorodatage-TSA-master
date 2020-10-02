# Serveur de signature et d'horodatage
Ce sont les instructions pour installer un serveur de signature de document électronique et d'horodatage. Le serveur utilise le logiciel gratuit Signserver et dispose de plusieurs services disponibles dans un serveur de signature sans surveillance et horodaté (RFC-3161). Le service de signature sans assistance vous permet de profiter d'une API HTTP pour signer des documents de manière centralisée, ce qui simplifie les processus pour les utilisateurs. Ce serveur doit utiliser des certificats (P12, JKS) émis par une autorité de certification telle que EJBCA . Les instructions d'installation peuvent être exécutées depuis Ubuntu Bionics.

# Exigences
OpenJDK 8

<a href="https://developers.redhat.com/products/eap/overview">JBoss EAP 7.0</a>

<a href="https://sourceforge.net/projects/signserver/files/signserver/4.0/signserver-ce-4.0.0-bin.zip/download">SignServer CE 4.0</a>
 

# Installez SignServer

Téléchargez ce référentiel et enregistrez-le sur votre serveur dans le dossier / opt. Assurez-vous de télécharger et d'ajouter le ZIP JBoss et Signserver dans ce même dossier.

Modifiez le nom de domaine de votre serveur en modifiant le fichier creer-certificats.sh. Ces certificats seront utilisés pour offrir le HTTPS, ils ne seront pas utilisés pour signer des documents.

Préparez votre serveur en exécutant les commandes depuis la console, sélectionnez le fichier qui correspond à votre système d'exploitation (install-jessie.sh ou install-xenial.sh).

Entrez dans le dossier 'configurer-jboss' et ouvrez le fichier commandes-jboss.txt. Exécutez ces commandes une par une, vous devez vous assurer que JBoss traite chaque commande avec succès une par une.

L'interface publique sera disponible à l'adresse https: // [adresse IP du serveur]: 8442 / signserver

La même page est disponible pour l'accès privé à l'aide de l'authentification TLS, uniquement pour les navigateurs sur lesquels le certificat client est installé à partir de https: // [ip serveur]: 8443 / signeserver /.

Nous n'avons encore configuré aucun service, le serveur dispose de plusieurs pages de test qui peuvent être utilisées une fois que les services sont prêts:

https: // [adresse IP du serveur]: 8442 / signserver / demo /

L'étape suivante consiste à configurer les services à l'aide des certificats d'une autorité de certification. Pour cet exemple, deux certificats P12 ont été générés:

timestamp.p12: de End-UserCA, est un certificat avec les attributs nécessaires pour les horodatages. 
signaturePDF.p12 de End-userCAsignerPDF,  est un certificat avec les attributs nécessaires pour signer des documents PDF.
Ces fichiers se trouvent dans le dossier «services» de ce référentiel.

 	     RootCA
     ------ | --------
     |               |

    End-UserCA     SubCApdfSigner
# Service d'horodatage

Pour configurer le service TimeStamp, il faut d'abord créer un CryptoToken qui utilise le fichier timestamp.p12. Vous pouvez utiliser un autre fichier / magasin de certificat d'horodatage et le configurer dans timestamp-crypto.properties en modifiant les valeurs suivantes:

     WORKERGENID1.NAME= NOMBRE-CRYPTO-TOKEN

     WORKERGENID1.KEYSTORETYPE=PKCS12

     WORKERGENID1.KEYSTOREPATH=/path pour le .p12/p12

    WORKERGENID1.KEYSTOREPASSWORD=mot_de_passe

Ensuite, nous devons créer et activer un processus qui assiste aux demandes d'horodatage. Dans le fichier timestamp.properties, modifiez ces variables comme il convient:

    WORKERGENID1.NAME= [nom du processsus d'horodatage]

    WORKERGENID1.CRYPTOTOKEN= [Nom du Crypto-Token]

    WORKERGENID1.DEFAULTKEY=[utulisateur/CN du certificat]

    WORKERGENID1.TSA=[DN de l'autorité d'horodatage]


Ensuite, nous devons créer et activer un processus TSA. Ensuite, exécutez les commandes suivantes, assurez-vous d'utiliser le numéro de processus correspondant (au lieu de 1 et 2) selon les informations fournies par la commande 'bin/signeserver getstatus brief all':

    su signer;

    cd /opt/signserver;

    bin/signserver getstatus brief all;

    bin/signserver setproperties services/timestamp-crypto.properties

    bin/signserver setproperties services/timestamp.properties

    bin/signserver reload 1

    bin/signserver reload 2

    bin/signserver getstatus brief all

Avec cela, nous avons activé le service d'horodatage et disponible pour répondre aux requêtes HTTP POST.Pour le tester, nous pouvons utiliser OpenSSL comme indiqué ci-dessous:

    touch donnees.txt;

    echo "Test du service d'horodatage" >> donnees.txt;
    openssl ts -query -data donnees.txt -cert -sha256 -no_nonce -out requetes.tsq;

    cat requetes.tsq | curl -s -S -H 'Content-Type: Application/timestamp-query' \
     --data-binary @- http://localhost:8080/signserver/process?workerName=TimeStampSigner -o reponses.tsr;

##Lecture de la reponse d'horodatage

    openssl ts -reply -in reponse.tsr -text;
 
# Service de signature PDF

Pour configurer le service de signature PDF, il faut d'abord créer un CryptoToken qui utilise le fichier signaturePDF.p12 ou un autre magasin/certificat. Dans le fichier pdf-crypto.properties, modifiez ces variables comme il convient:

    WORKERGENID1.NAME= Nom du Crypto-Token

    WORKERGENID1.KEYSTORETYPE=PKCS12

    WORKERGENID1.KEYSTOREPATH=/path du certificat p12/p12

    WORKERGENID1.KEYSTOREPASSWORD=mot_de_passe

Ensuite, nous devons créer et activer un processus qui répond aux demandes de signature. Dans le fichier pdfsigner.properties, modifiez ces variables comme il convient:

    WORKERGENID1.NAME= nom de processus de signature (ex: PDFSigner)

    WORKERGENID1.CRYPTOTOKEN=Non du Crypto Token

    WORKERGENID1.DEFAULTKEY=[Utilisateur/CN du certificat]

    WORKERGENID1.REASON= [Description de la signature]

    WORKERGENID1.VISIBLE_SIGNATURE_CUSTOM_IMAGE_BASE64=[image/logo de la signature]

    WORKERGENID1.TSA_WORKER=[Nom du service d'horodatage]


Ensuite, exécutez les commandes suivantes, assurez-vous d'utiliser le numéro de processus correspondant (au lieu de 3 et 4) selon les informations fournies par la commande 'bin /signeserver getstatus brief all':

    su signer;

    cd /opt/signserver;

    bin/signserver getstatus brief all;

    bin/signserver setproperties services/pdf-crypto.properties;

    bin/signserver setproperties services/pdfsigner.properties;

    bin/signserver reload 3;

    bin/signserver reload 4;

    bin/signserver getstatus brief all;


Ce service de signature est disponible via les appels HTTP POST comme décrit dans la documentation de l'API . Par exemple:

     curl -i -H 'Content-Type: Application/x-www-form-urlencoded' --data-binary @documento-pour_signature.pdf -X POST http://localhost:8080/signserver/process?workerName=PDFSigner   -   o document-signed.pdf

Le service répond avec le fichier 'document-signed.pdf', c'est le PDF signé, vous pouvez voir la signature à l'aide d'Acrobat Reader. Pour vérifier la signature, vous devez configurer la validation de signature numérique dans Acrobat Reader . L'image et l'apparence de la signature peuvent être modifiées dans la configuration du service dans services/pdfsigner.properties.

À ce stade, vous pouvez déjà essayer l'exemple de signature PDF à partir de https://[ip serveur]:8442/signeserver/demo/pdfsign.jsp

Pour configurer d'autres services, vous pouvez consulter les exemples sous /opt/signeserver/doc/sample-configs/.

# URL des services

Ensuite, nous allons créer des URL de service plus conviviales. Pour cela, nous utiliserons NGINX comme proxy inverse.

    apt-get install nginx-light
  
Modifiez la configuration dans /etc/nginx/sites-enabled / default et ajoutez les blocs suivants:

       location /timestamp {
          proxy_pass http://localhost:8080/signserver/process?workerName=TimeStampSigner;
          proxy_read_timeout 30s;
          #temps maxi du POST
          client_max_body_size 5M;
        }
       
       location /signer-pdf {
          proxy_pass http://localhost:8080/signserver/process?workerName=PDFSigner;
          proxy_read_timeout 30s;
          #ttemps maxi du POST
          client_max_body_size 5M;
        }
Après avoir redémarré le service NGINX, nous pouvons consommer des services en utilisant la nouvelle URL:

    http: //[adresse IP du serveur]/timestamp
    http: //[adresse IP du serveur]/signer-pdf
# Licence

Ce travail est couvert dans le cadre de la stratégie de développement des services e-Gouvernance du Gouvernement de Madagascaret en tant que tel est un travail de valeur publique soumis aux directives de la politique de données ouvertes et de la licence CC-BY-SA .
