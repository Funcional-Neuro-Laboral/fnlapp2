import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/profile_data.dart';

class ProfileScreen extends StatelessWidget {
  final ProfileData? profileData;
  final Function onLogout;

  ProfileScreen({
    required this.profileData,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isWeb = screenWidth > 900;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(isWeb, isTablet),
                      Expanded(
                        child: _buildContent(isWeb, isTablet, screenWidth),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool isWeb, bool isTablet) {
    return Padding(
      padding: EdgeInsets.only(
        left: isWeb ? 200 : (isTablet ? 80 : 16),
        top: isWeb ? 40 : (isTablet ? 50 : 60),
        right: isWeb ? 40 : (isTablet ? 30 : 20),
      ),
      child: Text(
        'Perfil',
        style: TextStyle(
          color: const Color(0xFF212121),
          fontSize: isWeb ? 42 : (isTablet ? 34 : 32),
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildContent(bool isWeb, bool isTablet, double screenWidth) {
    final maxWidth = isWeb ? 800.0 : double.infinity;
    final horizontalPadding = isWeb ? 40.0 : (isTablet ? 30.0 : 20.0);

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          children: [
            SizedBox(height: isWeb ? 20 : (isTablet ? 35 : 50)),
            _buildProfileImage(isWeb, isTablet),
            SizedBox(height: isWeb ? 25 : 20),
            _buildUserName(isWeb, isTablet),
            SizedBox(height: isWeb ? 35 : 30),
            _buildInfoGrid(isWeb, isTablet, screenWidth),
            SizedBox(height: isWeb ? 40 : (isTablet ? 35 : 30)),
            _buildLogoutButton(isWeb, isTablet),
            SizedBox(height: isWeb ? 30 : 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage(bool isWeb, bool isTablet) {
    final imageSize = isWeb ? 150.0 : (isTablet ? 140.0 : 130.0);

    return Container(
      width: imageSize,
      height: imageSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            Color(0xFF52178F),
            Color(0xFFA88BC7),
          ],
          begin: Alignment(1.00, 1.00),
          end: Alignment(1.00, 0.50),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8A67C8).withOpacity(0.3),
            blurRadius: isWeb ? 25 : 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: CircleAvatar(
          radius: (imageSize - 16) / 2,
          backgroundColor: Colors.transparent,
          backgroundImage: profileData?.profileImage != null
              ? NetworkImage(profileData!.profileImage!)
              : null,
          child: profileData?.profileImage == null
              ? Icon(
            Icons.person,
            size: isWeb ? 60 : (isTablet ? 55 : 50),
            color: const Color(0xFF4320AD),
          )
              : null,
        ),
      ),
    );
  }

  Widget _buildUserName(bool isWeb, bool isTablet) {
    return Text(
      "${profileData?.nombres ?? 'Usuario'} ${profileData?.apellidos ?? ''}",
      textAlign: TextAlign.center,
      style: TextStyle(
        color: const Color(0xFF212121),
        fontSize: isWeb ? 28 : (isTablet ? 26 : 24),
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildInfoGrid(bool isWeb, bool isTablet, double screenWidth) {
    final cardPadding = isWeb ? 25.0 : (isTablet ? 22.0 : 20.0);
    final cardSpacing = isWeb ? 16.0 : 12.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: const Color(0xFFDCD4F6),
        borderRadius: BorderRadius.circular(isWeb ? 25 : 20),
      ),
      child: Column(
        children: [
          if (isWeb && screenWidth > 1200)
          // Layout horizontal para pantallas muy anchas
            Row(
              children: [
                Expanded(child: _buildInfoCard(
                    icon: Icons.email_outlined,
                    title: 'ID',
                    value: profileData?.email.split('@')[0] ?? 'No disponible',
                    isWeb: isWeb,
                    isTablet: isTablet
                )),
                SizedBox(width: cardSpacing),
                Expanded(child: _buildInfoCard(
                    icon: Icons.female,
                    title: 'Género',
                    value: '--',
                    isWeb: isWeb,
                    isTablet: isTablet
                )),
                SizedBox(width: cardSpacing),
                Expanded(child: _buildInfoCard(
                    icon: Icons.calendar_month_outlined,
                    title: 'Edad',
                    value: '--',
                    isWeb: isWeb,
                    isTablet: isTablet
                )),
                SizedBox(width: cardSpacing),
                Expanded(child: _buildInfoCard(
                    icon: Icons.business_outlined,
                    title: 'Centro',
                    value: profileData?.nombreEmpresa ?? 'No disponible',
                    isWeb: isWeb,
                    isTablet: isTablet
                )),
              ],
            )
          else
          // Layout en grid 2x2 para el resto de pantallas
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.email_outlined,
                        title: 'ID',
                        value: profileData?.email.split('@')[0] ?? 'No disponible',
                        isWeb: isWeb,
                        isTablet: isTablet,
                      ),
                    ),
                    SizedBox(width: cardSpacing),
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.female,
                        title: 'Género',
                        value: '--',
                        isWeb: isWeb,
                        isTablet: isTablet,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: cardSpacing),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.calendar_month_outlined,
                        title: 'Edad',
                        value: '--',
                        isWeb: isWeb,
                        isTablet: isTablet,
                      ),
                    ),
                    SizedBox(width: cardSpacing),
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.business_outlined,
                        title: 'Centro',
                        value: profileData?.nombreEmpresa ?? 'No disponible',
                        isWeb: isWeb,
                        isTablet: isTablet,
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required bool isWeb,
    required bool isTablet,
  }) {
    final cardPadding = isWeb ? 20.0 : (isTablet ? 18.0 : 16.0);
    final iconSize = isWeb ? 24.0 : (isTablet ? 22.0 : 20.0);
    final titleFontSize = isWeb ? 16.0 : 15.0;
    final valueFontSize = isWeb ? 14.0 : 13.0;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isWeb ? 15 : 10),
        boxShadow: isWeb
            ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isWeb ? 10 : 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF0EEFF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF4320AD),
              size: iconSize,
            ),
          ),
          SizedBox(width: isWeb ? 15 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF3D3D3D),
                    fontSize: titleFontSize,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: valueFontSize,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(bool isWeb, bool isTablet) {
    final buttonPadding = isWeb ? 20.0 : 16.0;
    final fontSize = isWeb ? 18.0 : 16.0;
    final horizontalMargin = isWeb ? 0.0 : 20.0;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: isWeb ? 400 : double.infinity,
      ),
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
      child: ElevatedButton(
        onPressed: () => onLogout(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF6D4BD8),
          padding: EdgeInsets.symmetric(
            horizontal: 32,
            vertical: buttonPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
            side: const BorderSide(
              color: Color(0xFF6D4BD8),
              width: 1.5,
            ),
          ),
          elevation: isWeb ? 2 : 0,
          shadowColor: isWeb ? Colors.black.withOpacity(0.1) : null,
        ),
        child: Text(
          'Cerrar sesión',
          style: TextStyle(
            color: const Color(0xFF6D4BD8),
            fontSize: fontSize,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /*@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF5027D0),
        title: Text(
          'Perfil',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 1,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildProfileInfo(constraints.maxWidth),
                    const SizedBox(height: 20), // Espaciado extra si es necesario
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileInfo(double screenWidth) {
    return Container(
      constraints: BoxConstraints(maxWidth: screenWidth * 0.85),
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Se ajusta al contenido
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildProfileImage(screenWidth),
          const SizedBox(height: 20),
          _buildProfileDetails(),
          const SizedBox(height: 20),
          _buildAdditionalInfo(),
          const Divider(height: 30, thickness: 1, color: Colors.grey),
          const SizedBox(height: 20),
          _buildLogoutButton(screenWidth),
          const SizedBox(height: 10),
          Text(
            'Versión 2.3',
            style: GoogleFonts.roboto(fontSize: 12.0, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(double screenWidth) {
    return CircleAvatar(
      radius: screenWidth * 0.15, // Tamaño dinámico basado en el ancho de la pantalla
      backgroundColor: const Color(0xFFEEE8FB),
      backgroundImage: profileData?.profileImage != null
          ? NetworkImage(profileData!.profileImage!)
          : null,
      child: profileData?.profileImage == null
          ? Icon(
              Icons.person,
              size: screenWidth * 0.15, // Tamaño dinámico
              color: const Color(0xFF5027D0),
            )
          : null,
    );
  }

  Widget _buildProfileDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          profileData?.nombres ?? 'Usuario',
          style: GoogleFonts.roboto(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          (profileData?.nombres ?? 'Usuario') + " " + (profileData?.apellidos ?? ''),
          style: GoogleFonts.roboto(
            fontSize: 16.0,
            fontWeight: FontWeight.w400,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
            Icons.email, 'Correo:', profileData?.email ?? 'No disponible'),
        const SizedBox(height: 10),
        _buildInfoRow(Icons.star, 'Nivel jerárquico:',
            profileData?.hierarchicalLevel ?? 'No disponible'),
        const SizedBox(height: 10),
        _buildInfoRow(Icons.business, 'Empresa:',
            profileData?.nombreEmpresa ?? 'No disponible'),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF5027D0), size: 20),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w500,
            fontSize: 14.0,
            color: Colors.black87,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.roboto(
              fontSize: 14.0,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(double screenWidth) {
    return ElevatedButton.icon(
      onPressed: () => onLogout(),
      icon: const Icon(Icons.logout, size: 18, color: Colors.white),
      label: Text(
        'Cerrar sesión',
        style: GoogleFonts.roboto(fontWeight: FontWeight.w500),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5027D0),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.1, // Padding dinámico
          vertical: 15,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }*/
}